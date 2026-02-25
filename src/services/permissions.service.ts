import type { UserRoleAssignment } from '../types/auth.types';

export interface AccessScope {
  tenantIds: string[];
  departmentIds: string[];
  programIds: string[];
  orgUnitIds: string[];
}

export class PermissionsService {
  static calculateAccessScope(roleAssignments: UserRoleAssignment[]): AccessScope {
    const scope: AccessScope = {
      tenantIds: [],
      departmentIds: [],
      programIds: [],
      orgUnitIds: []
    };

    for (const assignment of roleAssignments) {
      if (assignment.tenant_id && !scope.tenantIds.includes(assignment.tenant_id)) {
        scope.tenantIds.push(assignment.tenant_id);
      }

      if (assignment.department_id && !scope.departmentIds.includes(assignment.department_id)) {
        scope.departmentIds.push(assignment.department_id);
      }

      if (assignment.program_id && !scope.programIds.includes(assignment.program_id)) {
        scope.programIds.push(assignment.program_id);
      }

      if (assignment.organization_unit_id && !scope.orgUnitIds.includes(assignment.organization_unit_id)) {
        scope.orgUnitIds.push(assignment.organization_unit_id);
      }
    }

    return scope;
  }

  static hasPermission(
    roleAssignments: UserRoleAssignment[],
    requiredPermission: string
  ): boolean {
    return roleAssignments.some(assignment => {
      const permissions = assignment.role?.permissions as string[] | undefined;
      return permissions?.includes(requiredPermission) || false;
    });
  }

  static canAccessProgram(
    roleAssignments: UserRoleAssignment[],
    programId: string
  ): boolean {
    return roleAssignments.some(assignment => {
      if (assignment.program_id === programId) {
        return true;
      }

      if (assignment.department_id && !assignment.program_id) {
        return true;
      }

      if (assignment.tenant_id && !assignment.department_id && !assignment.program_id) {
        return true;
      }

      return false;
    });
  }

  static canAccessDepartment(
    roleAssignments: UserRoleAssignment[],
    departmentId: string
  ): boolean {
    return roleAssignments.some(assignment => {
      if (assignment.department_id === departmentId) {
        return true;
      }

      if (assignment.tenant_id && !assignment.department_id) {
        return true;
      }

      return false;
    });
  }

  static canAccessTenant(
    roleAssignments: UserRoleAssignment[],
    tenantId: string
  ): boolean {
    return roleAssignments.some(assignment => assignment.tenant_id === tenantId);
  }

  static getAccessibleProgramIds(roleAssignments: UserRoleAssignment[]): string[] {
    const programIds = new Set<string>();

    for (const assignment of roleAssignments) {
      if (assignment.program_id) {
        programIds.add(assignment.program_id);
      }
    }

    return Array.from(programIds);
  }

  static hasRole(
    roleAssignments: UserRoleAssignment[],
    roleName: string
  ): boolean {
    return roleAssignments.some(assignment => assignment.role?.name === roleName);
  }

  static isSystemAdmin(roleAssignments: UserRoleAssignment[]): boolean {
    return this.hasRole(roleAssignments, 'SYSTEM_ADMIN');
  }

  static isTenantAdmin(roleAssignments: UserRoleAssignment[]): boolean {
    return this.hasRole(roleAssignments, 'DEPARTMENT_HEAD');
  }
}
