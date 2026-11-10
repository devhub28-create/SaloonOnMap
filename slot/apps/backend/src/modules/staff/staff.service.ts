import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Staff, StaffStatus } from "../../entities";

@Injectable()
export class StaffService {
  constructor(
    @InjectRepository(Staff)
    private readonly staffRepository: Repository<Staff>,
  ) {}

  async getSalonStaff(salonId: string) {
    try {
      const list = await this.staffRepository.find({
        where: { salon_id: salonId },
        order: { created_at: "ASC" },
      });

      return list.map((s) => {
        const parts = s.name.split(" ");
        const initials =
          parts.length >= 2
            ? `${parts[0][0]}${parts[1][0]}`.toUpperCase()
            : s.name.substring(0, 2).toUpperCase();
        return {
          id: s.id,
          name: s.name,
          roleTitle: s.role_title,
          status: s.status,
          initials,
        };
      });
    } catch (_) {
      return [];
    }
  }

  private toStaffStatus(status?: string) {
    const normalized = (status || "").toUpperCase().replace(/\s+/g, "_");
    if (normalized === StaffStatus.IN_SERVICE) return StaffStatus.IN_SERVICE;
    if (normalized === StaffStatus.BREAK) return StaffStatus.BREAK;
    return StaffStatus.AVAILABLE;
  }

  private toStaffResponse(staff: Staff) {
    const parts = staff.name.split(" ");
    const initials =
      parts.length >= 2
        ? `${parts[0][0]}${parts[1][0]}`.toUpperCase()
        : staff.name.substring(0, 2).toUpperCase();
    return {
      id: staff.id,
      name: staff.name,
      roleTitle: staff.role_title,
      status: staff.status,
      initials,
    };
  }

  async addStaff(
    dto: { name: string; roleTitle?: string; status?: string },
    salonId?: string,
  ) {
    if (!salonId) {
      throw new BadRequestException("salonId is required to add staff.");
    }

    const newStaff = this.staffRepository.create({
      salon_id: salonId,
      name: dto.name,
      role_title: dto.roleTitle || "Stylist",
      status: this.toStaffStatus(dto.status),
    });

    const saved = await this.staffRepository.save(newStaff);
    return this.toStaffResponse(saved);
  }

  async updateStaff(
    id: string,
    dto: { name?: string; roleTitle?: string; status?: string },
    salonId?: string,
  ) {
    const staff = await this.staffRepository.findOne({
      where: salonId ? { id, salon_id: salonId } : { id },
    });
    if (!staff) {
      throw new NotFoundException(`Staff member with ID ${id} not found`);
    }
    if (dto.name !== undefined) staff.name = dto.name;
    if (dto.roleTitle !== undefined) staff.role_title = dto.roleTitle;
    if (dto.status !== undefined) staff.status = this.toStaffStatus(dto.status);
    return this.toStaffResponse(await this.staffRepository.save(staff));
  }

  async deleteStaff(id: string, salonId?: string) {
    const result = await this.staffRepository.delete(
      salonId ? { id, salon_id: salonId } : { id },
    );
    if (!result.affected) {
      throw new NotFoundException(`Staff member with ID ${id} not found`);
    }
    return { success: true, message: "Staff member deleted" };
  }
}
