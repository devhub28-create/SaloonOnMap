import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from "@nestjs/common";

@Injectable()
export class TenantGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest();
    const user = req.user;

    if (!user) {
      throw new ForbiddenException("Tenant access requires authentication.");
    }

    // System Admins bypass tenant restriction
    if (user.role === "ADMIN" || user.role === "SUPER_ADMIN") {
      return true;
    }

    const requestedSalonId =
      req.query?.salonId || req.body?.salonId || req.params?.salonId;

    // Derived salon identity attached to authenticated user token/session
    const userSalonId = user.salonId || user.salon_id;

    if (!userSalonId) {
      throw new ForbiddenException(
        "Tenant access requires a salon assignment.",
      );
    }

    if (user.salonActive !== true) {
      throw new ForbiddenException('Salon account is pending approval or inactive.');
    }

    if (requestedSalonId && requestedSalonId !== userSalonId) {
      throw new ForbiddenException(
        `Cross-tenant violation: Access denied for salon ${requestedSalonId}.`,
      );
    }

    // Attach verified tenant salon_id to request
    req.tenantSalonId = userSalonId;
    return true;
  }
}
