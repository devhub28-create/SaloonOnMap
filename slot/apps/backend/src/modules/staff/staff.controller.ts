import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Query,
  Body,
  Req,
  UseGuards,
} from "@nestjs/common";
import { ApiTags, ApiOperation } from "@nestjs/swagger";
import { StaffService } from "./staff.service";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { RolesGuard } from "../auth/guards/roles.guard";
import { TenantGuard } from "../auth/guards/tenant.guard";
import { Roles } from "../auth/decorators/roles.decorator";

@ApiTags("Staff")
@Controller()
export class StaffController {
  constructor(private readonly staffService: StaffService) {}

  @Get("salons/:id/staff")
  @ApiOperation({ summary: "Get available stylists/staff for a salon" })
  async getSalonStaff(@Param("id") salonId: string) {
    return this.staffService.getSalonStaff(salonId);
  }

  @Get("partner/staff")
  @UseGuards(JwtAuthGuard, RolesGuard, TenantGuard)
  @Roles("SALON_OWNER", "SALON_STAFF", "ADMIN")
  @ApiOperation({ summary: "Get partner team and schedules" })
  async getPartnerStaff(@Req() req: any, @Query("salonId") salonId?: string) {
    const effectiveSalonId = req.tenantSalonId || salonId;
    if (!effectiveSalonId) return [];
    return this.staffService.getSalonStaff(effectiveSalonId);
  }

  @Post("partner/staff")
  @UseGuards(JwtAuthGuard, RolesGuard, TenantGuard)
  @Roles("SALON_OWNER", "ADMIN")
  @ApiOperation({ summary: "Add a new staff member to partner salon" })
  async addPartnerStaff(
    @Req() req: any,
    @Body()
    dto: {
      name: string;
      roleTitle?: string;
      status?: string;
      salonId?: string;
    },
  ) {
    return this.staffService.addStaff(dto, req.tenantSalonId || dto.salonId);
  }

  @Patch("partner/staff/:id")
  @UseGuards(JwtAuthGuard, RolesGuard, TenantGuard)
  @Roles("SALON_OWNER", "ADMIN")
  @ApiOperation({ summary: "Update a partner staff member" })
  async updatePartnerStaff(
    @Param("id") id: string,
    @Body() dto: { name?: string; roleTitle?: string; status?: string },
    @Req() req: any,
  ) {
    return this.staffService.updateStaff(id, dto, req.tenantSalonId);
  }

  @Delete("partner/staff/:id")
  @UseGuards(JwtAuthGuard, RolesGuard, TenantGuard)
  @Roles("SALON_OWNER", "ADMIN")
  @ApiOperation({ summary: "Delete a staff member from partner salon" })
  async deletePartnerStaff(@Param("id") id: string, @Req() req: any) {
    return this.staffService.deleteStaff(id, req.tenantSalonId);
  }
}
