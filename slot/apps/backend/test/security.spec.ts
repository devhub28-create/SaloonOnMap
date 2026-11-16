import { RolesGuard } from "../src/modules/auth/guards/roles.guard";
import { TenantGuard } from "../src/modules/auth/guards/tenant.guard";
import { ForbiddenException } from "@nestjs/common";
import { Reflector } from "@nestjs/core";

describe("Security & Multi-Tenant RBAC Tests", () => {
  let rolesGuard: RolesGuard;
  let tenantGuard: TenantGuard;
  let reflector: Reflector;

  beforeEach(() => {
    reflector = new Reflector();
    rolesGuard = new RolesGuard(reflector);
    tenantGuard = new TenantGuard();
  });

  function mockContext(
    user: any,
    requiredRoles: string[] = ["ADMIN"],
    queryParams: any = {},
  ) {
    jest.spyOn(reflector, "getAllAndOverride").mockReturnValue(requiredRoles);

    return {
      getHandler: () => ({}),
      getClass: () => ({}),
      switchToHttp: () => ({
        getRequest: () => ({
          user,
          query: queryParams,
        }),
      }),
    } as any;
  }

  it("unauthenticated user -> throws ForbiddenException", () => {
    const context = mockContext(null, ["ADMIN"]);
    expect(() => rolesGuard.canActivate(context)).toThrow(ForbiddenException);
  });

  it("customer accessing admin API -> throws ForbiddenException", () => {
    const context = mockContext({ role: "CUSTOMER" }, ["ADMIN"]);
    expect(() => rolesGuard.canActivate(context)).toThrow(ForbiddenException);
  });

  it("super admin accessing admin API -> allowed", () => {
    const context = mockContext({ role: "SUPER_ADMIN" }, ["ADMIN"]);
    expect(rolesGuard.canActivate(context)).toBe(true);
  });

  it("legacy admin accessing an ADMIN route -> allowed", () => {
    const context = mockContext({ role: "ADMIN" }, ["ADMIN"]);
    expect(rolesGuard.canActivate(context)).toBe(true);
  });

  it("legacy admin accessing a SUPER_ADMIN-only route -> denied", () => {
    const context = mockContext({ role: "ADMIN" }, ["SUPER_ADMIN"]);
    expect(() => rolesGuard.canActivate(context)).toThrow(ForbiddenException);
  });

  it("Salon A accessing Salon B partner API -> throws ForbiddenException", () => {
    const context = mockContext(
      { role: "SALON_OWNER", salonId: "SALON_A", salonActive: true },
      ["SALON_OWNER"],
      { salonId: "SALON_B" },
    );
    expect(() => tenantGuard.canActivate(context)).toThrow(ForbiddenException);
  });

  it("Salon A accessing Salon A partner API -> allowed", () => {
    const context = mockContext(
      { role: "SALON_OWNER", salonId: "SALON_A", salonActive: true },
      ["SALON_OWNER"],
      { salonId: "SALON_A" },
    );
    expect(tenantGuard.canActivate(context)).toBe(true);
  });
});
