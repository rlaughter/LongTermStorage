import { supabase } from '@/lib/supabase';

export interface AuditEvent {
  id: string;
  tenant_id: string;
  event_type: string;
  entity_type: string;
  entity_id: string | null;
  document_id: string | null;
  user_id: string;
  ip_address: string | null;
  user_agent: string | null;
  action: string;
  details: any;
  created_at: string;
  user_email?: string;
  document_filename?: string;
}

export const auditService = {
  async getAuditLogs(options: {
    documentId?: string;
    limit?: number;
    offset?: number;
  } = {}) {
    const { documentId, limit = 50, offset = 0 } = options;

    let query = supabase
      .from('audit_events')
      .select('*')
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (documentId) {
      query = query.eq('document_id', documentId);
    }

    const { data: events, error: eventsError } = await query;

    if (eventsError) {
      console.error('Error fetching audit logs:', eventsError);
      throw eventsError;
    }

    if (!events || events.length === 0) {
      return [];
    }

    const userIds = [...new Set(events.map(e => e.user_id))];
    const documentIds = [...new Set(events.map(e => e.document_id).filter(Boolean))];

    const { data: profiles } = await supabase
      .from('user_profiles')
      .select('user_id, email')
      .in('user_id', userIds);

    const { data: documents } = documentIds.length > 0
      ? await supabase
          .from('documents')
          .select('id, filename')
          .in('id', documentIds)
      : { data: [] };

    const profileMap = new Map((profiles || []).map(p => [p.user_id, p.email]));
    const documentMap = new Map((documents || []).map(d => [d.id, d.filename]));

    return events.map((event: any) => ({
      ...event,
      user_email: profileMap.get(event.user_id) || 'Unknown',
      document_filename: event.document_id ? documentMap.get(event.document_id) || null : null
    }));
  },

  async createAuditEvent(event: {
    event_type: string;
    entity_type: string;
    entity_id?: string;
    document_id?: string;
    action: string;
    details?: any;
  }) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    const { data: profile } = await supabase
      .from('user_profiles')
      .select('tenant_id')
      .eq('user_id', user.id)
      .maybeSingle();

    if (!profile) return;

    const { error } = await supabase
      .from('audit_events')
      .insert({
        tenant_id: profile.tenant_id,
        user_id: user.id,
        ...event
      });

    if (error) {
      console.error('Error creating audit event:', error);
    }
  },

  getEventTypeColor(eventType: string): string {
    const colorMap: Record<string, string> = {
      'CREATE': 'success',
      'UPDATE': 'info',
      'DELETE': 'danger',
      'DOWNLOAD': 'warning',
      'VIEW': 'secondary',
      'LOGIN': 'info',
      'LOGOUT': 'secondary'
    };
    return colorMap[eventType] || 'secondary';
  },

  getEventTypeIcon(eventType: string): string {
    const iconMap: Record<string, string> = {
      'CREATE': 'pi-plus',
      'UPDATE': 'pi-pencil',
      'DELETE': 'pi-trash',
      'DOWNLOAD': 'pi-download',
      'VIEW': 'pi-eye',
      'LOGIN': 'pi-sign-in',
      'LOGOUT': 'pi-sign-out'
    };
    return iconMap[eventType] || 'pi-info-circle';
  }
};
