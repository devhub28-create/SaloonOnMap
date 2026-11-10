import { IsString, IsOptional, IsNotEmpty, IsInt, IsArray } from 'class-validator';

export class SaveLookDto {
  @IsString()
  @IsOptional()
  jobId?: string;

  @IsString()
  @IsOptional()
  archetypeId?: string;

  @IsInt()
  @IsOptional()
  optionNumber?: number;

  @IsString()
  @IsNotEmpty()
  originalImageUrl: string;

  @IsString()
  @IsNotEmpty()
  styledImageUrl: string;

  @IsString()
  @IsOptional()
  hairStyle?: string;

  @IsString()
  @IsOptional()
  beardStyle?: string;

  @IsString()
  @IsOptional()
  title?: string;

  @IsString()
  @IsOptional()
  notes?: string;

  @IsString()
  @IsOptional()
  whyItSuits?: string;

  @IsInt()
  @IsOptional()
  suitabilityScore?: number;

  @IsString()
  @IsOptional()
  maintenanceLevel?: string;

  @IsString()
  @IsOptional()
  hairLengthCm?: string;

  @IsString()
  @IsOptional()
  beardLengthMm?: string;

  @IsString()
  @IsOptional()
  stylingProducts?: string;

  @IsArray()
  @IsOptional()
  barberInstructions?: string[];
}
