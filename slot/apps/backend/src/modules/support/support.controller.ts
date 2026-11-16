import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Request,
  UseGuards,
} from "@nestjs/common";
import {
  IsBoolean,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from "class-validator";
import { SupportTicketPriority, SupportTicketStatus } from "../../entities";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { RolesGuard } from "../auth/guards/roles.guard";
import { Roles } from "../auth/decorators/roles.decorator";
import { SupportService } from "./support.service";

class CreateTicketDto {
  @IsString() @MinLength(2) @MaxLength(60) category: string;
  @IsString() @MinLength(3) @MaxLength(160) subject: string;
  @IsString() @MinLength(5) @MaxLength(3000) message: string;
  @IsOptional() @IsUUID() bookingId?: string;
  @IsOptional()
  @IsIn(Object.values(SupportTicketPriority))
  priority?: SupportTicketPriority;
}
class MessageDto {
  @IsString() @MinLength(2) @MaxLength(3000) message: string;
  @IsOptional() @IsBoolean() internalNote?: boolean;
}
class TicketStatusDto {
  @IsIn(Object.values(SupportTicketStatus)) status: SupportTicketStatus;
}

@Controller()
@UseGuards(JwtAuthGuard)
export class SupportController {
  constructor(private readonly support: SupportService) {}
  @Post("support/tickets") create(
    @Request() req: any,
    @Body() dto: CreateTicketDto,
  ) {
    return this.support.createTicket(req.user, dto);
  }
  @Get("support/tickets/my") mine(@Request() req: any) {
    return this.support.getMyTickets(req.user.id);
  }
  @Post("support/tickets/:id/messages") requesterMessage(
    @Param("id") id: string,
    @Request() req: any,
    @Body() dto: MessageDto,
  ) {
    return this.support.addRequesterMessage(id, req.user, dto.message);
  }

  @Get("admin/support-tickets")
  @UseGuards(RolesGuard)
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN", "SUPPORT_ADMIN")
  adminTickets(
    @Query("search") search?: string,
    @Query("status") status?: string,
    @Query("priority") priority?: string,
    @Query("page") page?: string,
  ) {
    return this.support.getAdminTickets({
      search,
      status,
      priority,
      page: page ? Number(page) : 1,
    });
  }
  @Post("admin/support-tickets/:id/messages")
  @UseGuards(RolesGuard)
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN", "SUPPORT_ADMIN")
  adminMessage(
    @Param("id") id: string,
    @Request() req: any,
    @Body() dto: MessageDto,
  ) {
    return this.support.adminReply(id, req.user, dto.message, dto.internalNote);
  }
  @Patch("admin/support-tickets/:id/status")
  @UseGuards(RolesGuard)
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN", "SUPPORT_ADMIN")
  status(
    @Param("id") id: string,
    @Request() req: any,
    @Body() dto: TicketStatusDto,
  ) {
    return this.support.updateStatus(id, dto.status, req.user);
  }
}
