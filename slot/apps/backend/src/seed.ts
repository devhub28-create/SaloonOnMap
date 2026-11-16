import { DataSource } from "typeorm";
import {
  User,
  UserRole,
  CustomerProfile,
  Salon,
  SalonUser,
  Service,
  SalonService,
  Combo,
  Seat,
  SeatStatus,
  Staff,
  StaffStatus,
  Booking,
  BookingStatus,
  BookingService,
  BookingHold,
  BookingStatusHistory,
  AuditLog,
  Notification,
  Offer,
  OfferType,
  OfferScope,
  SalonApprovalHistory,
  StaffSchedule,
} from "./entities";
import * as dotenv from "dotenv";

dotenv.config();

export async function runSeed(dataSource?: DataSource) {
  let ds = dataSource;
  if (!ds) {
    const dbUrl = process.env.DATABASE_URL || process.env.POSTGRES_URL;
    ds = new DataSource({
      type: "postgres",
      ...(dbUrl
        ? { url: dbUrl, ssl: { rejectUnauthorized: false } }
        : {
            host: process.env.DB_HOST || "localhost",
            port: parseInt(process.env.DB_PORT || "5432", 10),
            username: process.env.DB_USERNAME || "manishdubey",
            password: process.env.DB_PASSWORD || "",
            database: process.env.DB_DATABASE || "slot_db",
            ssl:
              process.env.DB_SSL === "true"
                ? { rejectUnauthorized: false }
                : false,
          }),
      entities: [
        User,
        CustomerProfile,
        Salon,
        SalonUser,
        Service,
        SalonService,
        Combo,
        Seat,
        Staff,
        Booking,
        BookingService,
        BookingHold,
        BookingStatusHistory,
        AuditLog,
        Notification,
        Offer,
        SalonApprovalHistory,
        StaffSchedule,
      ],
      synchronize: true,
    });
    await ds.initialize();
  }

  console.log("🌱 Starting fresh database seed...");

  const userRepo = ds.getRepository(User);
  const profileRepo = ds.getRepository(CustomerProfile);
  const salonRepo = ds.getRepository(Salon);
  const salonUserRepo = ds.getRepository(SalonUser);
  const serviceRepo = ds.getRepository(Service);
  const salonServiceRepo = ds.getRepository(SalonService);
  const comboRepo = ds.getRepository(Combo);
  const seatRepo = ds.getRepository(Seat);
  const staffRepo = ds.getRepository(Staff);
  const offerRepo = ds.getRepository(Offer);

  // 1. Create Admin & Partner Owners & Customers
  await userRepo.save(
    userRepo.create({
      phone: "+919999999999",
      name: "Slot Administrator",
      email: "admin@slot.com",
      role: UserRole.SUPER_ADMIN,
    }),
  );

  const ownerRhea = await userRepo.save(
    userRepo.create({
      phone: "+919876543215",
      name: "Rhea Sharma",
      email: "rhea@maisonmuse.com",
      role: UserRole.SALON_OWNER,
    }),
  );

  const ownerVikram = await userRepo.save(
    userRepo.create({
      phone: "+919876543216",
      name: "Vikram Shekhawat",
      email: "vikram@blades.com",
      role: UserRole.SALON_OWNER,
    }),
  );

  const ownerAnand = await userRepo.save(
    userRepo.create({
      phone: "+919876543217",
      name: "Anand Verma",
      email: "anand@royalcut.com",
      role: UserRole.SALON_OWNER,
    }),
  );

  const ownerPooja = await userRepo.save(
    userRepo.create({
      phone: "+919876543218",
      name: "Pooja Agarwal",
      email: "pooja@glamour.com",
      role: UserRole.SALON_OWNER,
    }),
  );

  const ownerSameer = await userRepo.save(
    userRepo.create({
      phone: "+919876543219",
      name: "Sameer Joshi",
      email: "sameer@urbanluxe.com",
      role: UserRole.SALON_OWNER,
    }),
  );

  const ownerKavita = await userRepo.save(
    userRepo.create({
      phone: "+919876543220",
      name: "Kavita Roy",
      email: "kavita@velvetrose.com",
      role: UserRole.SALON_OWNER,
    }),
  );

  const customerAanya = await userRepo.save(
    userRepo.create({
      phone: "+919876543210",
      name: "Aanya Tiwari",
      email: "aanya@example.com",
      role: UserRole.CUSTOMER,
    }),
  );
  await profileRepo.save(
    profileRepo.create({ user_id: customerAanya.id, preferred_gender: "ALL" }),
  );

  await userRepo.save(
    userRepo.create({
      phone: "+919876543211",
      name: "Kabir S.",
      email: "kabir@example.com",
      role: UserRole.CUSTOMER,
    }),
  );

  await userRepo.save(
    userRepo.create({
      phone: "+919876543212",
      name: "Meera Rao",
      email: "meera@example.com",
      role: UserRole.CUSTOMER,
    }),
  );

  await userRepo.save(
    userRepo.create({
      phone: "+919876543213",
      name: "Tanay Gupta",
      email: "tanay@example.com",
      role: UserRole.CUSTOMER,
    }),
  );

  // 2. Create Global Base Services
  const svcCut = await serviceRepo.save(
    serviceRepo.create({
      name: "Signature Haircut",
      category: "Hair",
      target_gender: "UNISEX",
      description: "Consultation, expert scissor cut & precision styling",
    }),
  );
  const svcBeard = await serviceRepo.save(
    serviceRepo.create({
      name: "Beard Sculpt & Shape",
      category: "Beard",
      target_gender: "MEN",
      description: "Hot towel prep, trimmer detailing & soothing beard oil",
    }),
  );
  const svcSpa = await serviceRepo.save(
    serviceRepo.create({
      name: "Hydra Hair Spa",
      category: "Spa",
      target_gender: "UNISEX",
      description: "Deep scalp massage, keratin infusion steam & wash",
    }),
  );
  const svcFacial = await serviceRepo.save(
    serviceRepo.create({
      name: "Glow Facial & Cleanup",
      category: "Face",
      target_gender: "UNISEX",
      description: "Charcoal detox, exfoliating scrub & radiant herbal glow",
    }),
  );
  const svcBlowdry = await serviceRepo.save(
    serviceRepo.create({
      name: "Layered Cut & Blowdry",
      category: "Hair",
      target_gender: "WOMEN",
      description: "Custom layer shaping & high-volume salon blowdry",
    }),
  );
  const svcKeratin = await serviceRepo.save(
    serviceRepo.create({
      name: "Keratin Hair Spa",
      category: "Spa",
      target_gender: "WOMEN",
      description: "Intense frizz-taming keratin protein therapy",
    }),
  );
  const svcMani = await serviceRepo.save(
    serviceRepo.create({
      name: "Gel Nail Art & Manicure",
      category: "Nails",
      target_gender: "WOMEN",
      description: "Cuticle care, hydrating massage & gel lacquer finish",
    }),
  );

  // 3. Create Salons (Indore + Bengaluru)
  const salonsData = [
    // Indore Salons (Local connected device area)
    {
      name: "The Royal Cut Barber Lounge",
      slug: "royal-cut-vijaynagar",
      address: "Plot 14, Scheme 54, PU-4, Vijay Nagar",
      city: "Indore",
      area: "Vijay Nagar",
      target_gender: "MEN",
      latitude: 22.7533,
      longitude: 75.8937,
      rating: 4.9,
      review_count: 512,
      opening_time: "09:00",
      closing_time: "21:30",
      cover_image:
        "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&q=80&w=1000",
      owner: ownerAnand,
    },
    {
      name: "Glamour & Grace Studio",
      slug: "glamour-grace-palasia",
      address: "5/2, Old Palasia, Main Road",
      city: "Indore",
      area: "Palasia",
      target_gender: "WOMEN",
      latitude: 22.7244,
      longitude: 75.8839,
      rating: 4.9,
      review_count: 420,
      opening_time: "10:00",
      closing_time: "20:30",
      cover_image:
        "https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&q=80&w=1000",
      owner: ownerPooja,
    },
    {
      name: "Urban Luxe Unisex Salon",
      slug: "urban-luxe-malharganj",
      address: "MG Road, Near Malharganj Tahsil",
      city: "Indore",
      area: "Malharganj Tahsil",
      target_gender: "UNISEX",
      latitude: 22.7196,
      longitude: 75.8577,
      rating: 4.8,
      review_count: 368,
      opening_time: "09:00",
      closing_time: "21:00",
      cover_image:
        "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&q=80&w=1000",
      owner: ownerSameer,
    },
    // Bengaluru Salons
    {
      name: "Maison Muse",
      slug: "maison-muse-indiranagar",
      address: "100 Feet Road, Indiranagar",
      city: "Bengaluru",
      area: "Indiranagar",
      target_gender: "UNISEX",
      latitude: 12.9784,
      longitude: 77.6408,
      rating: 4.9,
      review_count: 2841,
      opening_time: "09:00",
      closing_time: "21:00",
      cover_image:
        "https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&q=80&w=1000",
      owner: ownerRhea,
    },
    {
      name: "Blades & Shears Men's Salon",
      slug: "blades-shears-hsr",
      address: "27th Main, Sector 1, HSR Layout",
      city: "Bengaluru",
      area: "HSR Layout",
      target_gender: "MEN",
      latitude: 12.9116,
      longitude: 77.6389,
      rating: 4.8,
      review_count: 890,
      opening_time: "08:30",
      closing_time: "21:30",
      cover_image:
        "https://images.unsplash.com/photo-1622286342621-4bd786c2447c?auto=format&fit=crop&q=80&w=1000",
      owner: ownerVikram,
    },
    {
      name: "Velvet & Rose Beauty Studio",
      slug: "velvet-rose-indiranagar",
      address: "12th Main Road, Indiranagar",
      city: "Bengaluru",
      area: "Indiranagar",
      target_gender: "WOMEN",
      latitude: 12.9716,
      longitude: 77.6412,
      rating: 4.9,
      review_count: 1980,
      opening_time: "10:00",
      closing_time: "20:00",
      cover_image:
        "https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&q=80&w=1000",
      owner: ownerKavita,
    },
  ];

  for (const sData of salonsData) {
    const salon = await salonRepo.save(
      salonRepo.create({
        name: sData.name,
        slug: sData.slug,
        address: sData.address,
        city: sData.city,
        area: sData.area,
        target_gender: sData.target_gender,
        latitude: sData.latitude,
        longitude: sData.longitude,
        rating: sData.rating,
        review_count: sData.review_count,
        opening_time: sData.opening_time,
        closing_time: sData.closing_time,
        cover_image: sData.cover_image,
        is_active: true,
      }),
    );

    // Link owner
    await salonUserRepo.save(
      salonUserRepo.create({
        salon_id: salon.id,
        user_id: sData.owner.id,
        role: "OWNER",
      }),
    );

    // Create Seats (Chairs)
    for (let chairNum = 1; chairNum <= 5; chairNum++) {
      await seatRepo.save(
        seatRepo.create({
          salon_id: salon.id,
          seat_number: chairNum,
          label: `Chair ${chairNum}`,
          status: SeatStatus.AVAILABLE,
        }),
      );
    }

    // Create Staff
    await staffRepo.save(
      staffRepo.create({
        salon_id: salon.id,
        name: sData.target_gender === "WOMEN" ? "Maya Kapoor" : "Arjun Mehta",
        role_title:
          sData.target_gender === "WOMEN" ? "Senior Stylist" : "Master Barber",
        status: StaffStatus.AVAILABLE,
        job_count_today: 3,
      }),
    );
    await staffRepo.save(
      staffRepo.create({
        salon_id: salon.id,
        name: sData.target_gender === "WOMEN" ? "Pooja Verma" : "Rohan Sen",
        role_title: "Hair & Spa Specialist",
        status: StaffStatus.AVAILABLE,
        job_count_today: 2,
      }),
    );

    // Link Services depending on gender
    if (sData.target_gender === "MEN" || sData.target_gender === "UNISEX") {
      await salonServiceRepo.save(
        salonServiceRepo.create({
          salon_id: salon.id,
          service_id: svcCut.id,
          price: 399,
          duration_minutes: 30,
          is_available: true,
        }),
      );
      await salonServiceRepo.save(
        salonServiceRepo.create({
          salon_id: salon.id,
          service_id: svcBeard.id,
          price: 249,
          duration_minutes: 20,
          is_available: true,
        }),
      );
      await salonServiceRepo.save(
        salonServiceRepo.create({
          salon_id: salon.id,
          service_id: svcSpa.id,
          price: 799,
          duration_minutes: 45,
          is_available: true,
        }),
      );
      await salonServiceRepo.save(
        salonServiceRepo.create({
          salon_id: salon.id,
          service_id: svcFacial.id,
          price: 699,
          duration_minutes: 35,
          is_available: true,
        }),
      );

      // Create Dedicated Combo Services to ensure unique (salon_id, service_id)
      const comboRoyalSvc = await serviceRepo.save(
        serviceRepo.create({
          name: "Gentleman's Royal Package",
          category: "Combo",
          target_gender: "MEN",
          description: "Haircut + Beard Sculpt + Hydra Spa",
        }),
      );
      const comboRoyal = await comboRepo.save(
        comboRepo.create({
          salon_id: salon.id,
          name: "Gentleman's Royal Package",
          description: "Haircut + Beard Sculpt + Hydra Spa",
          price: 1199,
          original_price: 1447,
          duration_minutes: 75,
          is_bestseller: true,
        }),
      );
      await salonServiceRepo.save(
        salonServiceRepo.create({
          id: comboRoyal.id,
          salon_id: salon.id,
          service_id: comboRoyalSvc.id,
          price: 1199,
          duration_minutes: 75,
          is_available: true,
        }),
      );

      const comboDuoSvc = await serviceRepo.save(
        serviceRepo.create({
          name: "Quick Groom Duo",
          category: "Combo",
          target_gender: "MEN",
          description: "Signature Haircut + Beard Sculpt",
        }),
      );
      const comboDuo = await comboRepo.save(
        comboRepo.create({
          salon_id: salon.id,
          name: "Quick Groom Duo",
          description: "Signature Haircut + Beard Sculpt",
          price: 549,
          original_price: 648,
          duration_minutes: 45,
          is_bestseller: false,
        }),
      );
      await salonServiceRepo.save(
        salonServiceRepo.create({
          id: comboDuo.id,
          salon_id: salon.id,
          service_id: comboDuoSvc.id,
          price: 549,
          duration_minutes: 45,
          is_available: true,
        }),
      );
    }

    if (sData.target_gender === "WOMEN" || sData.target_gender === "UNISEX") {
      await salonServiceRepo.save(
        salonServiceRepo.create({
          salon_id: salon.id,
          service_id: svcBlowdry.id,
          price: 699,
          duration_minutes: 45,
          is_available: true,
        }),
      );
      await salonServiceRepo.save(
        salonServiceRepo.create({
          salon_id: salon.id,
          service_id: svcKeratin.id,
          price: 1299,
          duration_minutes: 60,
          is_available: true,
        }),
      );
      await salonServiceRepo.save(
        salonServiceRepo.create({
          salon_id: salon.id,
          service_id: svcMani.id,
          price: 599,
          duration_minutes: 30,
          is_available: true,
        }),
      );

      // Create Dedicated Combo Services for Women
      const comboBridalSvc = await serviceRepo.save(
        serviceRepo.create({
          name: "Bridal Glow & Spa Package",
          category: "Combo",
          target_gender: "WOMEN",
          description: "Layered Cut + Keratin Spa + Glow Facial",
        }),
      );
      const comboBridal = await comboRepo.save(
        comboRepo.create({
          salon_id: salon.id,
          name: "Bridal Glow & Spa Package",
          description: "Layered Cut + Keratin Spa + Glow Facial",
          price: 2499,
          original_price: 2997,
          duration_minutes: 90,
          is_bestseller: true,
        }),
      );
      await salonServiceRepo.save(
        salonServiceRepo.create({
          id: comboBridal.id,
          salon_id: salon.id,
          service_id: comboBridalSvc.id,
          price: 2499,
          duration_minutes: 90,
          is_available: true,
        }),
      );

      const comboRefreshSvc = await serviceRepo.save(
        serviceRepo.create({
          name: "Hair Refresh Duo",
          category: "Combo",
          target_gender: "WOMEN",
          description: "Blowdry Styling + Keratin Spa",
        }),
      );
      const comboRefresh = await comboRepo.save(
        comboRepo.create({
          salon_id: salon.id,
          name: "Hair Refresh Duo",
          description: "Blowdry Styling + Keratin Spa",
          price: 1699,
          original_price: 1998,
          duration_minutes: 65,
          is_bestseller: false,
        }),
      );
      await salonServiceRepo.save(
        salonServiceRepo.create({
          id: comboRefresh.id,
          salon_id: salon.id,
          service_id: comboRefreshSvc.id,
          price: 1699,
          duration_minutes: 65,
          is_available: true,
        }),
      );
    }
  }

  // 4. Create Active Offers
  await offerRepo.save(
    offerRepo.create({
      code: "SLOT20",
      name: "Welcome 20% Off",
      discount_type: OfferType.PERCENTAGE,
      discount_value: 20,
      scope: OfferScope.PLATFORM,
      min_booking_amount: 300,
      is_active: true,
      valid_from: new Date(),
      valid_until: new Date(Date.now() + 365 * 24 * 3600 * 1000),
    }),
  );

  await offerRepo.save(
    offerRepo.create({
      code: "FIRSTCHAIR",
      name: "First Chair Booking",
      discount_type: OfferType.FIXED,
      discount_value: 150,
      scope: OfferScope.PLATFORM,
      min_booking_amount: 500,
      is_active: true,
      valid_from: new Date(),
      valid_until: new Date(Date.now() + 365 * 24 * 3600 * 1000),
    }),
  );

  console.log("✅ Fresh database seed completed successfully!");
  if (!dataSource) {
    await ds.destroy();
  }
}

if (require.main === module) {
  runSeed().catch((err) => {
    console.error("❌ Seed error:", err);
    process.exit(1);
  });
}
