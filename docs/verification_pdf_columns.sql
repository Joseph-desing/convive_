alter table public.properties
add column if not exists verification_pdf_url text;

alter table public.roommate_searches
add column if not exists verification_pdf_url text;
