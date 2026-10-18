-- Vaccine Table
INSERT INTO Vaccine (
   vaccine_name,
   vaccine_type,
   manufacturer,
   description
)
VALUES
   (
       'Engerix B',
       'Recombinant',
       'GlaxoSmithKline Australia',
       'Registered for use from birth. Administer within 7 days of birth (ideally within 24 hours).'
   ),
   (
       'Infanrix hexa',
       'Combination',
       'GlaxoSmithKline Australia',
       'Registered for use in infants and children aged >=6 weeks.'
   ),
   (
       'Vaxelis',
       'Combination',
       'Maxx Pharma Pty Ltd',
       'Registered for use in infants and toddlers aged >=6 weeks.'
   ),
   (
       'Prevenar 20',
       'Conjugate',
       'Pfizer Australia',
       'Registered for use in people aged >=6 weeks.'
   ),
   (
       'Rotarix',
       'Live attenuated',
       'GlaxoSmithKline Australia',
       'Registered for use in infants, with an upper age limit for dose 2 of 24 weeks.'
   ),
   (
       'Bexsero',
       'Recombinant',
       'GlaxoSmithKline Australia',
       'Registered for use in people aged >=2 months.'
   ),
   (
       'Flucelvax',
       'Inactivated',
       'Seqirus',
       'Registered for use in people aged >=6 months.'
   ),
   (
       'Fluzone',
       'Inactivated',
       'Sanofi-Aventis Australia',
       'Registered for use in people aged >=6 months.'
   ),
   (
       'Vaxigrip',
       'Inactivated',
       'Sanofi-Aventis Australia',
       'Registered for use in people aged >=6 months.'
   ),
   (
       'Influvac',
       'Inactivated',
       'Viatris Pty Ltd',
       'Registered for use in people aged >=6 months.'
   ),
   (
       'Nimenrix',
       'Conjugate',
       'Pfizer Australia',
       'Registered for use in people aged >=6 weeks.'
   ),
   (
       'Priorix',
       'Combination',
       'GlaxoSmithKline Australia',
       'Registered for use in people aged >=12 months.'
   ),
   (
       'Infanrix',
       'Combination',
       'GlaxoSmithKline Australia',
       'Registered for primary immunisation in infants aged 2–12 months and as a booster in children aged 15 months to 6 years.'
   ),
   (
       'Tripacel',
       'Combination',
       'Sanofi-Aventis Australia',
       'Registered for primary immunisation in infants aged 2–12 months and as a booster in children aged 15 months to 8 years.'
   ),
   (
       'Priorix Tetra',
       'Combination',
       'GlaxoSmithKline Australia',
       'Registered for use in people aged >=9 months.'
   ),
   (
       'Act-HIB',
       'Conjugate',
       'Sanofi-Aventis Australia',
       'Registered for use in infants and children aged 2 months to 5 years.'
   ),
   (
       'Infanrix-IPV',
       'Combination',
       'GlaxoSmithKline Australia',
       'Registered for primary immunisation in infants aged >=6 weeks and as a booster in children aged <=6 years.'
   ),
   (
       'Quadracel',
       'Combination',
       'Sanofi Pasteur Pty',
       'Registered for primary immunisation in infants aged 2–12 months and as a booster in children aged 15 months to 6 years.'
   ),
   (
       'Boostrix',
       'Combination',
       'GlaxoSmithKline Australia',
       'Registered as a booster in people aged >=4 years.'
   ),
   (
       'Adacel',
       'Combination',
       'Sanofi-Aventis Australia',
       'Registered as a booster for people aged >=10 years.'
   ),
   (
       'Gardasil 9',
       'Recombinant',
       'Merck Sharp & Dohme (Australia)',
       'Registered for use in females and males aged 9 to <46 years. Contains the major capsid (L1) protein of HPV types 6, 11, 16, 18, 31, 33, 45, 52 and 58.'
   ),
   (
       'MenQuadfi',
       'Conjugate',
       'Sanofi-Aventis Australia',
       'Registered for use in people aged >=6 weeks. Also known as MenACWY-TT, quadrivalent meningococcal (serogroups A, C, W, Y)-tetanus toxoid.'
   );


-- Prevented_Disease Table
INSERT INTO Prevented_Disease (vaccine_id, disease_name)
SELECT v.vaccine_id, d.disease_name
FROM (
   VALUES
       ('Engerix B', 'Hepatitis B'),


       ('Infanrix hexa', 'Diphtheria'),
       ('Infanrix hexa', 'Tetanus'),
       ('Infanrix hexa', 'Pertussis'),
       ('Infanrix hexa', 'Hepatitis B'),
       ('Infanrix hexa', 'Poliovirus'),
       ('Infanrix hexa', 'Haemophilus Influenzae Type b'),


       ('Vaxelis', 'Diphtheria'),
       ('Vaxelis', 'Tetanus'),
       ('Vaxelis', 'Pertussis'),
       ('Vaxelis', 'Poliovirus'),
       ('Vaxelis', 'Hepatitis B'),
       ('Vaxelis', 'Haemophilus Influenzae Type b'),


       ('Prevenar 20', 'Pneumococcal'),
       ('Rotarix', 'Rotavirus'),
       ('Bexsero', 'Meningococcal B'),
       ('Influvac', 'Influenza'),
       ('Nimenrix', 'Meningococcal ACWY'),


       ('Priorix', 'Measles'),
       ('Priorix', 'Mumps'),
       ('Priorix', 'Rubella'),


       ('Infanrix', 'Diphtheria'),
       ('Infanrix', 'Tetanus'),
       ('Infanrix', 'Pertussis'),


       ('Tripacel', 'Diphtheria'),
       ('Tripacel', 'Tetanus'),
       ('Tripacel', 'Pertussis'),


       ('Priorix Tetra', 'Measles'),
       ('Priorix Tetra', 'Mumps'),
       ('Priorix Tetra', 'Rubella'),
       ('Priorix Tetra', 'Varicella'),


       ('Act-HIB', 'Haemophilus Influenzae Type b'),


       ('Infanrix-IPV', 'Diphtheria'),
       ('Infanrix-IPV', 'Pertussis'),
       ('Infanrix-IPV', 'Poliovirus'),


       ('Quadracel', 'Diphtheria'),
       ('Quadracel', 'Tetanus'),
       ('Quadracel', 'Pertussis'),
       ('Quadracel', 'Poliovirus'),


       ('Boostrix', 'Diphtheria'),
       ('Boostrix', 'Tetanus'),
       ('Boostrix', 'Pertussis'),


       ('Adacel', 'Diphtheria'),
       ('Adacel', 'Tetanus'),
       ('Adacel', 'Pertussis'),


       ('Gardasil 9', 'Human papillomavirus'),


       ('MenQuadfi', 'Meningococcal (serogroups A, C, W, Y)'),
       ('MenQuadfi', 'Tetanus')
) AS d(vaccine_name, disease_name)
JOIN Vaccine v ON v.vaccine_name = d.vaccine_name;




