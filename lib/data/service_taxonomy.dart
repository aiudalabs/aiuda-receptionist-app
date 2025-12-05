// Service Taxonomy - Manual seed data
// Structure: Industry ’ Category ’ Tags

const Map<String, dynamic> serviceTaxonomyData = {
  'industries': [
    // 1. BEAUTY & PERSONAL CARE
    {
      'id': 'beauty',
      'name': 'Beauty & Personal Care',
      'icon': 'face',
      'description': 'Hair, nails, skin, and beauty services',
      'categories': [
        {
          'id': 'hair',
          'name': 'Hair Services',
          'tags': [
            {'id': 'haircut', 'name': 'Haircut'},
            {'id': 'hair_coloring', 'name': 'Hair Coloring'},
            {'id': 'highlights', 'name': 'Highlights'},
            {'id': 'balayage', 'name': 'Balayage'},
            {'id': 'hair_styling', 'name': 'Hair Styling'},
            {'id': 'blowout', 'name': 'Blowout'},
            {'id': 'extensions', 'name': 'Hair Extensions'},
            {'id': 'keratin', 'name': 'Keratin Treatment'},
            {'id': 'perm', 'name': 'Perm'},
            {'id': 'straightening', 'name': 'Hair Straightening'},
          ],
          'commonServices': ['Men\'s Haircut', 'Women\'s Haircut', 'Hair Color', 'Blowout']
        },
        {
          'id': 'nails',
          'name': 'Nail Services',
          'tags': [
            {'id': 'manicure', 'name': 'Manicure'},
            {'id': 'pedicure', 'name': 'Pedicure'},
            {'id': 'gel_nails', 'name': 'Gel Nails'},
            {'id': 'acrylic_nails', 'name': 'Acrylic Nails'},
            {'id': 'nail_art', 'name': 'Nail Art'},
            {'id': 'french_manicure', 'name': 'French Manicure'},
          ],
          'commonServices': ['Basic Manicure', 'Spa Pedicure', 'Gel Manicure']
        },
        {
          'id': 'skin',
          'name': 'Skin Care',
          'tags': [
            {'id': 'facial', 'name': 'Facial'},
            {'id': 'deep_cleansing', 'name': 'Deep Cleansing'},
            {'id': 'anti_aging', 'name': 'Anti-Aging Treatment'},
            {'id': 'acne_treatment', 'name': 'Acne Treatment'},
            {'id': 'microdermabrasion', 'name': 'Microdermabrasion'},
            {'id': 'chemical_peel', 'name': 'Chemical Peel'},
          ],
          'commonServices': ['Basic Facial', 'Deep Cleansing Facial']
        },
        {
          'id': 'makeup',
          'name': 'Makeup Services',
          'tags': [
            {'id': 'makeup_application', 'name': 'Makeup Application'},
            {'id': 'bridal_makeup', 'name': 'Bridal Makeup'},
            {'id': 'special_event', 'name': 'Special Event Makeup'},
            {'id': 'makeup_lesson', 'name': 'Makeup Lesson'},
          ],
          'commonServices': ['Special Event Makeup', 'Bridal Makeup']
        },
        {
          'id': 'waxing',
          'name': 'Waxing & Hair Removal',
          'tags': [
            {'id': 'eyebrow_wax', 'name': 'Eyebrow Waxing'},
            {'id': 'lip_wax', 'name': 'Lip Waxing'},
            {'id': 'full_body_wax', 'name': 'Full Body Wax'},
            {'id': 'brazilian_wax', 'name': 'Brazilian Wax'},
            {'id': 'threading', 'name': 'Threading'},
          ],
          'commonServices': ['Eyebrow Waxing', 'Full Face Threading']
        },
        {
          'id': 'barber',
          'name': 'Barbershop Services',
          'tags': [
            {'id': 'mens_haircut', 'name': 'Men\'s Haircut'},
            {'id': 'beard_trim', 'name': 'Beard Trim'},
            {'id': 'shave', 'name': 'Classic Shave'},
            {'id': 'fade', 'name': 'Fade'},
            {'id': 'taper', 'name': 'Taper'},
            {'id': 'lineup', 'name': 'Line Up'},
          ],
          'commonServices': ['Haircut & Beard Trim', 'Fade', 'Hot Towel Shave']
        },
      ]
    },

    // 2. AUTOMOTIVE SERVICES
    {
      'id': 'automotive',
      'name': 'Automotive Services',
      'icon': 'directions_car',
      'description': 'Vehicle maintenance, repair, and care',
      'categories': [
        {
          'id': 'maintenance',
          'name': 'Maintenance',
          'tags': [
            {'id': 'oil_change', 'name': 'Oil Change'},
            {'id': 'filter_replacement', 'name': 'Filter Replacement'},
            {'id': 'tire_rotation', 'name': 'Tire Rotation'},
            {'id': 'wheel_alignment', 'name': 'Wheel Alignment'},
            {'id': 'tune_up', 'name': 'Tune-Up'},
            {'id': 'inspection', 'name': 'Vehicle Inspection'},
            {'id': 'fluid_check', 'name': 'Fluid Check & Fill'},
          ],
          'commonServices': ['Oil Change', 'Basic Tune-Up', 'Vehicle Inspection']
        },
        {
          'id': 'repair',
          'name': 'Repair Services',
          'tags': [
            {'id': 'brake_repair', 'name': 'Brake Repair'},
            {'id': 'engine_repair', 'name': 'Engine Repair'},
            {'id': 'transmission', 'name': 'Transmission Service'},
            {'id': 'ac_repair', 'name': 'AC Repair'},
            {'id': 'electrical', 'name': 'Electrical Repair'},
            {'id': 'exhaust', 'name': 'Exhaust System'},
            {'id': 'suspension', 'name': 'Suspension Repair'},
          ],
          'commonServices': ['Brake Service', 'Engine Diagnostics', 'AC Repair']
        },
        {
          'id': 'tires',
          'name': 'Tire Services',
          'tags': [
            {'id': 'tire_change', 'name': 'Tire Change'},
            {'id': 'tire_repair', 'name': 'Tire Repair'},
            {'id': 'balancing', 'name': 'Tire Balancing'},
            {'id': 'new_tires', 'name': 'New Tire Installation'},
          ],
          'commonServices': ['Tire Change', 'Tire Rotation', 'Flat Tire Repair']
        },
        {
          'id': 'detailing',
          'name': 'Auto Detailing',
          'tags': [
            {'id': 'car_wash', 'name': 'Car Wash'},
            {'id': 'interior_detail', 'name': 'Interior Detailing'},
            {'id': 'exterior_detail', 'name': 'Exterior Detailing'},
            {'id': 'wax', 'name': 'Waxing'},
            {'id': 'polish', 'name': 'Polishing'},
            {'id': 'ceramic_coating', 'name': 'Ceramic Coating'},
          ],
          'commonServices': ['Full Detail', 'Interior Clean', 'Exterior Wash & Wax']
        },
      ]
    },

    // 3. HOME SERVICES
    {
      'id': 'home',
      'name': 'Home Services',
      'icon': 'home',
      'description': 'Plumbing, electrical, and home maintenance',
      'categories': [
        {
          'id': 'plumbing',
          'name': 'Plumbing',
          'tags': [
            {'id': 'leak_repair', 'name': 'Leak Repair'},
            {'id': 'pipe_installation', 'name': 'Pipe Installation'},
            {'id': 'drain_cleaning', 'name': 'Drain Cleaning'},
            {'id': 'water_heater', 'name': 'Water Heater Service'},
            {'id': 'toilet_repair', 'name': 'Toilet Repair'},
            {'id': 'faucet_repair', 'name': 'Faucet Repair'},
            {'id': 'emergency_plumbing', 'name': 'Emergency Plumbing'},
          ],
          'commonServices': ['Leak Repair', 'Drain Cleaning', 'Toilet Repair']
        },
        {
          'id': 'electrical',
          'name': 'Electrical',
          'tags': [
            {'id': 'wiring', 'name': 'Electrical Wiring'},
            {'id': 'outlet_installation', 'name': 'Outlet Installation'},
            {'id': 'light_fixture', 'name': 'Light Fixture Installation'},
            {'id': 'ceiling_fan', 'name': 'Ceiling Fan Installation'},
            {'id': 'circuit_breaker', 'name': 'Circuit Breaker Repair'},
            {'id': 'electrical_inspection', 'name': 'Electrical Inspection'},
          ],
          'commonServices': ['Outlet Repair', 'Light Installation', 'Electrical Inspection']
        },
        {
          'id': 'handyman',
          'name': 'Handyman',
          'tags': [
            {'id': 'furniture_assembly', 'name': 'Furniture Assembly'},
            {'id': 'tv_mounting', 'name': 'TV Mounting'},
            {'id': 'drywall_repair', 'name': 'Drywall Repair'},
            {'id': 'door_repair', 'name': 'Door Repair'},
            {'id': 'cabinet_installation', 'name': 'Cabinet Installation'},
            {'id': 'general_repairs', 'name': 'General Repairs'},
          ],
          'commonServices': ['Furniture Assembly', 'TV Mounting', 'General Handyman']
        },
        {
          'id': 'cleaning',
          'name': 'Cleaning Services',
          'tags': [
            {'id': 'house_cleaning', 'name': 'House Cleaning'},
            {'id': 'deep_cleaning', 'name': 'Deep Cleaning'},
            {'id': 'move_in_out', 'name': 'Move In/Out Cleaning'},
            {'id': 'carpet_cleaning', 'name': 'Carpet Cleaning'},
            {'id': 'window_cleaning', 'name': 'Window Cleaning'},
            {'id': 'pressure_washing', 'name': 'Pressure Washing'},
          ],
          'commonServices': ['Standard House Cleaning', 'Deep Cleaning', 'Move-Out Cleaning']
        },
        {
          'id': 'painting',
          'name': 'Painting',
          'tags': [
            {'id': 'interior_painting', 'name': 'Interior Painting'},
            {'id': 'exterior_painting', 'name': 'Exterior Painting'},
            {'id': 'cabinet_painting', 'name': 'Cabinet Painting'},
            {'id': 'trim_painting', 'name': 'Trim Painting'},
            {'id': 'wall_repair', 'name': 'Wall Repair & Painting'},
          ],
          'commonServices': ['Room Painting', 'Full Interior Paint', 'Exterior House Paint']
        },
        {
          'id': 'carpentry',
          'name': 'Carpentry',
          'tags': [
            {'id': 'custom_furniture', 'name': 'Custom Furniture'},
            {'id': 'deck_building', 'name': 'Deck Building'},
            {'id': 'shelving', 'name': 'Shelving Installation'},
            {'id': 'door_installation', 'name': 'Door Installation'},
            {'id': 'crown_molding', 'name': 'Crown Molding'},
          ],
          'commonServices': ['Custom Shelving', 'Deck Repair', 'Door Installation']
        },
      ]
    },

    // 4. HEALTH & WELLNESS
    {
      'id': 'wellness',
      'name': 'Health & Wellness',
      'icon': 'favorite',
      'description': 'Fitness, massage, and wellness services',
      'categories': [
        {
          'id': 'massage',
          'name': 'Massage Therapy',
          'tags': [
            {'id': 'swedish_massage', 'name': 'Swedish Massage'},
            {'id': 'deep_tissue', 'name': 'Deep Tissue Massage'},
            {'id': 'sports_massage', 'name': 'Sports Massage'},
            {'id': 'hot_stone', 'name': 'Hot Stone Massage'},
            {'id': 'prenatal_massage', 'name': 'Prenatal Massage'},
            {'id': 'reflexology', 'name': 'Reflexology'},
          ],
          'commonServices': ['1-Hour Massage', 'Deep Tissue Massage', 'Couples Massage']
        },
        {
          'id': 'fitness',
          'name': 'Fitness Training',
          'tags': [
            {'id': 'personal_training', 'name': 'Personal Training'},
            {'id': 'group_fitness', 'name': 'Group Fitness'},
            {'id': 'yoga', 'name': 'Yoga Classes'},
            {'id': 'pilates', 'name': 'Pilates'},
            {'id': 'nutritional_coaching', 'name': 'Nutritional Coaching'},
          ],
          'commonServices': ['Personal Training Session', 'Yoga Class', 'Fitness Assessment']
        },
      ]
    },

    // 5. PROFESSIONAL SERVICES
    {
      'id': 'professional',
      'name': 'Professional Services',
      'icon': 'business_center',
      'description': 'Legal, accounting, and consulting',
      'categories': [
        {
          'id': 'legal',
          'name': 'Legal Services',
          'tags': [
            {'id': 'consultation', 'name': 'Legal Consultation'},
            {'id': 'document_review', 'name': 'Document Review'},
            {'id': 'contract_drafting', 'name': 'Contract Drafting'},
            {'id': 'notary', 'name': 'Notary Services'},
          ],
          'commonServices': ['Legal Consultation', 'Document Review', 'Notary']
        },
        {
          'id': 'accounting',
          'name': 'Accounting',
          'tags': [
            {'id': 'tax_preparation', 'name': 'Tax Preparation'},
            {'id': 'bookkeeping', 'name': 'Bookkeeping'},
            {'id': 'payroll', 'name': 'Payroll Services'},
            {'id': 'financial_planning', 'name': 'Financial Planning'},
          ],
          'commonServices': ['Tax Return', 'Monthly Bookkeeping', 'Business Taxes']
        },
      ]
    },

    // 6. EDUCATION & TRAINING
    {
      'id': 'education',
      'name': 'Education & Training',
      'icon': 'school',
      'description': 'Tutoring, music, and language lessons',
      'categories': [
        {
          'id': 'tutoring',
          'name': 'Academic Tutoring',
          'tags': [
            {'id': 'math', 'name': 'Math Tutoring'},
            {'id': 'english', 'name': 'English Tutoring'},
            {'id': 'science', 'name': 'Science Tutoring'},
            {'id': 'test_prep', 'name': 'Test Preparation'},
          ],
          'commonServices': ['Math Tutoring', 'SAT Prep', 'English Tutoring']
        },
        {
          'id': 'music',
          'name': 'Music Lessons',
          'tags': [
            {'id': 'piano', 'name': 'Piano Lessons'},
            {'id': 'guitar', 'name': 'Guitar Lessons'},
            {'id': 'voice', 'name': 'Voice Lessons'},
            {'id': 'drums', 'name': 'Drum Lessons'},
          ],
          'commonServices': ['Piano Lessons', 'Guitar Lessons', 'Voice Training']
        },
        {
          'id': 'language',
          'name': 'Language Lessons',
          'tags': [
            {'id': 'english', 'name': 'English Lessons'},
            {'id': 'spanish', 'name': 'Spanish Lessons'},
            {'id': 'french', 'name': 'French Lessons'},
          ],
          'commonServices': ['English Lessons', 'Spanish Lessons', 'Conversation Practice']
        },
      ]
    },

    // 7. EVENTS & ENTERTAINMENT
    {
      'id': 'events',
      'name': 'Events & Entertainment',
      'icon': 'celebration',
      'description': 'Photography, DJ, catering, and event services',
      'categories': [
        {
          'id': 'photography',
          'name': 'Photography',
          'tags': [
            {'id': 'wedding_photo', 'name': 'Wedding Photography'},
            {'id': 'portrait', 'name': 'Portrait Photography'},
            {'id': 'event_photo', 'name': 'Event Photography'},
            {'id': 'product_photo', 'name': 'Product Photography'},
          ],
          'commonServices': ['Wedding Photography', 'Portrait Session', 'Event Coverage']
        },
        {
          'id': 'entertainment',
          'name': 'Entertainment',
          'tags': [
            {'id': 'dj', 'name': 'DJ Services'},
            {'id': 'live_music', 'name': 'Live Music'},
            {'id': 'mc', 'name': 'MC/Host'},
          ],
          'commonServices': ['Wedding DJ', 'Party DJ', 'Live Band']
        },
        {
          'id': 'catering',
          'name': 'Catering',
          'tags': [
            {'id': 'full_service', 'name': 'Full Service Catering'},
            {'id': 'drop_off', 'name': 'Drop-Off Catering'},
            {'id': 'buffet', 'name': 'Buffet Service'},
            {'id': 'bartending', 'name': 'Bartending Service'},
          ],
          'commonServices': ['Wedding Catering', 'Corporate Catering', 'Party Catering']
        },
      ]
    },

    // 8. PET SERVICES
    {
      'id': 'pets',
      'name': 'Pet Services',
      'icon': 'pets',
      'description': 'Pet grooming, training, and care',
      'categories': [
        {
          'id': 'grooming',
          'name': 'Pet Grooming',
          'tags': [
            {'id': 'dog_grooming', 'name': 'Dog Grooming'},
            {'id': 'cat_grooming', 'name': 'Cat Grooming'},
            {'id': 'nail_trimming', 'name': 'Nail Trimming'},
            {'id': 'bath', 'name': 'Pet Bath'},
          ],
          'commonServices': ['Dog Grooming', 'Cat Grooming', 'Full Service Grooming']
        },
        {
          'id': 'training',
          'name': 'Pet Training',
          'tags': [
            {'id': 'obedience', 'name': 'Obedience Training'},
            {'id': 'puppy_training', 'name': 'Puppy Training'},
            {'id': 'behavior', 'name': 'Behavior Modification'},
          ],
          'commonServices': ['Basic Obedience', 'Puppy Training', 'Private Training']
        },
        {
          'id': 'sitting',
          'name': 'Pet Sitting & Walking',
          'tags': [
            {'id': 'pet_sitting', 'name': 'Pet Sitting'},
            {'id': 'dog_walking', 'name': 'Dog Walking'},
            {'id': 'overnight_care', 'name': 'Overnight Care'},
          ],
          'commonServices': ['Dog Walking', 'Pet Sitting', 'Overnight Boarding']
        },
      ]
    },

    // 9. TECHNOLOGY SERVICES
    {
      'id': 'technology',
      'name': 'Technology Services',
      'icon': 'computer',
      'description': 'IT support, web design, and tech services',
      'categories': [
        {
          'id': 'it_support',
          'name': 'IT Support',
          'tags': [
            {'id': 'computer_repair', 'name': 'Computer Repair'},
            {'id': 'virus_removal', 'name': 'Virus Removal'},
            {'id': 'data_recovery', 'name': 'Data Recovery'},
            {'id': 'network_setup', 'name': 'Network Setup'},
            {'id': 'software_install', 'name': 'Software Installation'},
          ],
          'commonServices': ['Computer Repair', 'Virus Removal', 'Data Backup']
        },
        {
          'id': 'web',
          'name': 'Web Services',
          'tags': [
            {'id': 'web_design', 'name': 'Web Design'},
            {'id': 'web_development', 'name': 'Web Development'},
            {'id': 'seo', 'name': 'SEO Services'},
            {'id': 'ecommerce', 'name': 'E-commerce Setup'},
          ],
          'commonServices': ['Website Design', 'Website Development', 'SEO Optimization']
        },
      ]
    },

    // 10. CONSTRUCTION & RENOVATION
    {
      'id': 'construction',
      'name': 'Construction & Renovation',
      'icon': 'construction',
      'description': 'General contracting, roofing, and remodeling',
      'categories': [
        {
          'id': 'general',
          'name': 'General Contracting',
          'tags': [
            {'id': 'home_renovation', 'name': 'Home Renovation'},
            {'id': 'kitchen_remodel', 'name': 'Kitchen Remodel'},
            {'id': 'bathroom_remodel', 'name': 'Bathroom Remodel'},
            {'id': 'room_addition', 'name': 'Room Addition'},
          ],
          'commonServices': ['Kitchen Remodel', 'Bathroom Remodel', 'Home Addition']
        },
        {
          'id': 'roofing',
          'name': 'Roofing',
          'tags': [
            {'id': 'roof_repair', 'name': 'Roof Repair'},
            {'id': 'roof_replacement', 'name': 'Roof Replacement'},
            {'id': 'roof_inspection', 'name': 'Roof Inspection'},
            {'id': 'gutter_installation', 'name': 'Gutter Installation'},
          ],
          'commonServices': ['Roof Repair', 'Roof Replacement', 'Roof Inspection']
        },
        {
          'id': 'flooring',
          'name': 'Flooring',
          'tags': [
            {'id': 'hardwood', 'name': 'Hardwood Installation'},
            {'id': 'tile', 'name': 'Tile Installation'},
            {'id': 'carpet', 'name': 'Carpet Installation'},
            {'id': 'laminate', 'name': 'Laminate Flooring'},
          ],
          'commonServices': ['Hardwood Installation', 'Tile Installation', 'Floor Refinishing']
        },
      ]
    },
  ]
};
