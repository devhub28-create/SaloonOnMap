import { IsString, IsOptional, IsInt, Min, Max, IsBoolean, Equals } from 'class-validator';

export class GenerateStyleDto {
  @IsString()
  @IsOptional()
  imageBase64?: string;

  @IsString()
  @IsOptional()
  sideImageBase64?: string;

  @IsString()
  @IsOptional()
  backImageBase64?: string;

  @IsString()
  @IsOptional()
  hairStyle?: string;

  @IsString()
  @IsOptional()
  beardStyle?: string;

  @IsString()
  @IsOptional()
  hairColor?: string;

  @IsString()
  @IsOptional()
  beardColor?: string;

  @IsString()
  @IsOptional()
  maintenanceLevel?: string = 'any';

  @IsString()
  @IsOptional()
  styleVibe?: string = 'any';

  @IsString()
  @IsOptional()
  hairLengthPref?: string = 'any';

  @IsString()
  @IsOptional()
  beardPref?: string = 'any';

  @IsString()
  @IsOptional()
  mode?: string = 'storyboard';

  @IsInt()
  @Min(1)
  @Max(6)
  @IsOptional()
  variationsCount?: number = 6;

  @IsBoolean()
  @Equals(true, { message: 'User consent is required before processing facial photo' })
  consentGiven: boolean;

  @IsBoolean()
  @IsOptional()
  async?: boolean;
}
