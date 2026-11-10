import {
  Controller,
  Post,
  Get,
  Delete,
  Body,
  Param,
  UseGuards,
  Request,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiConsumes } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { AiStyleService } from './ai-style.service';
import { GenerateStyleDto } from './dto/generate-style.dto';
import { SaveLookDto } from './dto/save-look.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('AI Style Studio')
@Controller(['style-studio', 'ai-style'])
export class AiStyleController {
  constructor(private readonly aiStyleService: AiStyleService) {}

  @Get('options')
  @ApiOperation({ summary: 'Get available hairstyles, beards, preference filters, and colors' })
  getStyleOptions() {
    return this.aiStyleService.getStyleOptions();
  }

  @Get('health')
  @ApiOperation({ summary: 'Check local AI inference service health and availability' })
  checkHealth() {
    return this.aiStyleService.checkHealth();
  }

  @Post('analyze')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiConsumes('multipart/form-data', 'application/json')
  @UseInterceptors(FileInterceptor('image'))
  @ApiOperation({ summary: 'Analyze an uploaded portrait for quality, face shape, hair, eyewear, and facial hair' })
  async analyzePhoto(
    @Body() body: { imageBase64?: string },
    @UploadedFile() file?: any,
  ) {
    return await this.aiStyleService.analyzePhoto(file, body?.imageBase64);
  }

  @Post(['generations', 'generate'])
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiConsumes('multipart/form-data', 'application/json')
  @UseInterceptors(FileInterceptor('image'))
  @ApiOperation({ summary: 'Create a personalized hairstyle & beard generation job' })
  async generateStyle(
    @Request() req: any,
    @Body() dto: GenerateStyleDto,
    @UploadedFile() file?: any,
  ) {
    const customerId = req.user?.id || req.user?.userId || req.user?.sub;
    if (typeof dto.consentGiven === 'string') {
      dto.consentGiven = (dto.consentGiven as string).toLowerCase() === 'true';
    }
    if (typeof dto.variationsCount === 'string') {
      dto.variationsCount = parseInt(dto.variationsCount, 10);
    }
    if (typeof dto.async === 'string') {
      dto.async = (dto.async as string).toLowerCase() === 'true';
    }
    return await this.aiStyleService.generateStyle(customerId, dto, file);
  }

  @Get(['generations', 'jobs'])
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List generation jobs for the authenticated customer' })
  async listGenerations(@Request() req: any) {
    const customerId = req.user?.id || req.user?.userId || req.user?.sub;
    return await this.aiStyleService.listGenerations(customerId);
  }

  @Get(['generations/:id', 'jobs/:id'])
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get AI generation job status, analysis, and resulting variations' })
  async getJob(@Request() req: any, @Param('id') id: string) {
    const customerId = req.user?.id || req.user?.userId || req.user?.sub;
    return await this.aiStyleService.getJob(customerId, id);
  }

  @Get('generations/:id/looks')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get individual generated looks for a specific generation job' })
  async getGenerationLooks(@Request() req: any, @Param('id') id: string) {
    const customerId = req.user?.id || req.user?.userId || req.user?.sub;
    return await this.aiStyleService.getGenerationLooks(customerId, id);
  }

  @Delete(['generations/:id', 'jobs/:id'])
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete a generation job and its stored original/generated images' })
  async deleteGeneration(@Request() req: any, @Param('id') id: string) {
    const customerId = req.user?.id || req.user?.userId || req.user?.sub;
    return await this.aiStyleService.deleteGeneration(customerId, id);
  }

  @Post(['save-look', 'looks/:id/save'])
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Save an individual generated AI look to Customer profile' })
  async saveLook(@Request() req: any, @Body() dto: SaveLookDto) {
    const customerId = req.user?.id || req.user?.userId || req.user?.sub;
    return await this.aiStyleService.saveLook(customerId, dto);
  }

  @Get(['saved-looks', 'looks'])
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List all saved AI looks for current customer' })
  async getSavedLooks(@Request() req: any) {
    const customerId = req.user?.id || req.user?.userId || req.user?.sub;
    return await this.aiStyleService.getSavedLooks(customerId);
  }

  @Delete(['saved-looks/:id', 'looks/:id', 'looks/:id/save'])
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete a saved look belonging to current customer' })
  async deleteSavedLook(@Request() req: any, @Param('id') id: string) {
    const customerId = req.user?.id || req.user?.userId || req.user?.sub;
    return await this.aiStyleService.deleteSavedLook(customerId, id);
  }

  @Post('looks/:id/share')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Generate a share token and barber consultation summary for a saved look' })
  async shareLook(@Request() req: any, @Param('id') id: string) {
    const customerId = req.user?.id || req.user?.userId || req.user?.sub;
    return await this.aiStyleService.shareLook(customerId, id);
  }
}
