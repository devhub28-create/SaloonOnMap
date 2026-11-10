import {
  Controller,
  Get,
  Post,
  Param,
  Query,
  UseGuards,
  Request,
  UseInterceptors,
  UploadedFile,
  Body,
  BadRequestException,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiConsumes, ApiBody } from "@nestjs/swagger";
import { FileInterceptor } from "@nestjs/platform-express";
import { diskStorage } from "multer";
import * as path from "path";
import * as fs from "fs";
import { SalonsService } from "./salons.service";

@ApiTags("Salons & Home")
@Controller()
export class SalonsController {
  constructor(private readonly salonsService: SalonsService) {}

  @Get("customer/home")
  @ApiOperation({ summary: "Get customer home dashboard data" })
  async getCustomerHome(
    @Query("gender") gender?: string,
    @Query("lat") lat?: string,
    @Query("lng") lng?: string,
    @Query("area") area?: string,
  ) {
    const parsedLat = lat ? parseFloat(lat) : undefined;
    const parsedLng = lng ? parseFloat(lng) : undefined;
    return this.salonsService.getCustomerHome(
      gender || "MEN",
      undefined,
      parsedLat,
      parsedLng,
      area,
    );
  }

  @Get("customer/offers")
  @ApiOperation({ summary: "Get currently active customer offers" })
  async getCustomerOffers() {
    return this.salonsService.getActiveOffers();
  }

  @Get("salons")
  @ApiOperation({
    summary: "Search and explore salons by location, distance, and query",
  })
  async getSalons(
    @Query("search") search?: string,
    @Query("gender") gender?: string,
    @Query("lat") lat?: string,
    @Query("lng") lng?: string,
    @Query("area") area?: string,
  ) {
    const parsedLat = lat ? parseFloat(lat) : undefined;
    const parsedLng = lng ? parseFloat(lng) : undefined;
    return this.salonsService.getAllSalons(
      search,
      gender,
      parsedLat,
      parsedLng,
      area,
    );
  }

  @Get("salons/:id")
  @ApiOperation({
    summary: "Get detailed salon profile, operating hours, and services",
  })
  async getSalonById(@Param("id") id: string) {
    return this.salonsService.getSalonById(id);
  }

  @Get("salons/:id/available-slots")
  @ApiOperation({
    summary: "Get available dates, time slots, seats and staff for a salon",
  })
  async getAvailableSlots(
    @Param("id") id: string,
    @Query("date") date?: string,
    @Query("duration") duration?: string,
  ) {
    return this.salonsService.getAvailableSlots(
      id,
      date,
      duration ? parseInt(duration, 10) : undefined,
    );
  }

  @Post("salons/upload-image")
  @ApiOperation({ summary: "Upload salon cover or gallery photo (multipart or base64)" })
  @UseInterceptors(
    FileInterceptor("file", {
      storage: diskStorage({
        destination: (_req, _file, cb) => {
          const uploadPath = path.join(process.cwd(), "uploads", "salons");
          if (!fs.existsSync(uploadPath)) {
            fs.mkdirSync(uploadPath, { recursive: true });
          }
          cb(null, uploadPath);
        },
        filename: (_req, file, cb) => {
          const ext = path.extname(file.originalname) || ".jpg";
          const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
          cb(null, `salon-${uniqueSuffix}${ext}`);
        },
      }),
      limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
    }),
  )
  async uploadSalonImage(
    @UploadedFile() file?: any,
    @Body() body?: { imageBase64?: string; filename?: string },
  ) {
    if (file) {
      return {
        url: `/uploads/salons/${file.filename}`,
        filename: file.filename,
      };
    }

    if (body?.imageBase64) {
      const uploadPath = path.join(process.cwd(), "uploads", "salons");
      if (!fs.existsSync(uploadPath)) {
        fs.mkdirSync(uploadPath, { recursive: true });
      }
      let rawBase64 = body.imageBase64;
      let ext = ".jpg";
      if (rawBase64.startsWith("data:image/")) {
        const mime = rawBase64.substring(11, rawBase64.indexOf(";"));
        if (mime.includes("png")) ext = ".png";
        else if (mime.includes("webp")) ext = ".webp";
        rawBase64 = rawBase64.split(",")[1];
      }
      const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
      const filename = `salon-${uniqueSuffix}${ext}`;
      const filePath = path.join(uploadPath, filename);
      fs.writeFileSync(filePath, Buffer.from(rawBase64, "base64"));
      return {
        url: `/uploads/salons/${filename}`,
        filename,
      };
    }

    throw new BadRequestException("No image file or imageBase64 payload provided.");
  }
}
