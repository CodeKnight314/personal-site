# Richard Tang — Personal Site

Static personal site hosted on Netlify. Recently added a Supabase-backed admin board for writing and task management.

## Stack
- Pure static HTML + CSS (index + blog)
- Supabase (Postgres + Auth + RLS) for dynamic content
- Netlify hosting + deploy from GitHub

## Local development
```bash
# Just open the files or use any static server
python3 -m http.server 8000
# or the old local edit server (if still around)
```

The public pages (`index.html`, `blog.html`) work without Supabase keys.

## Admin board
The admin lives at `admin.html` (bookmark it — it's intentionally not linked in the public nav).

### First-time setup (Supabase)
1. Create a project at https://supabase.com/dashboard
2. Copy your **Project URL** and **anon public** key (Project Settings → API)
3. Open `admin.html` and `blog.html` and replace the two constants near the top:
   ```js
   const SUPABASE_URL = 'https://YOUR-PROJECT.supabase.co';
   const SUPABASE_ANON_KEY = 'eyJhbGci...';
   ```
   (Do the same in `blog.html`.)

4. In Supabase, go to **SQL Editor** and run the entire contents of `supabase/schema.sql`.
   - **Important**: Edit the file first and replace any remaining placeholder emails with `richardgtang@gmail.com` (the 5 RLS policy lines). The schema now defaults to this address.

5. Create your admin user:
   - Authentication → Users → **Add user** (or use the sign-up form in `admin.html` once, then disable new sign-ups if you want).
   - Use the exact same email you put in the RLS policies.

6. (Optional but recommended) In Supabase Auth settings, you can turn off "Enable email confirmations" for your single-user setup, or require it.

7. **Storage bucket for images/gifs** (required for the image upload button in the admin editor):
   - Go to **Storage** → **New bucket**
   - Name: `blog-images`
   - Make it **Public** (this is required so direct image URLs work in your Markdown posts and on the public blog)
   - Create the bucket
   - Then go to **SQL Editor** and run these policies (this is the secure part — only you can upload):

     ```sql
     -- Public can view images (needed for the blog to display them)
     create policy "Public can view blog images"
     on storage.objects for select
     to public
     using ( bucket_id = 'blog-images' );

     -- Only the admin can upload images
     create policy "Admin can upload images"
     on storage.objects for insert
     to authenticated
     with check (
       bucket_id = 'blog-images' 
       AND (auth.jwt() ->> 'email') = 'richardgtang@gmail.com'
     );

     -- Admin can update/replace images
     create policy "Admin can update images"
     on storage.objects for update
     to authenticated
     using (
       bucket_id = 'blog-images' 
       AND (auth.jwt() ->> 'email') = 'richardgtang@gmail.com'
     );

     -- Admin can delete images
     create policy "Admin can delete images"
     on storage.objects for delete
     to authenticated
     using (
       bucket_id = 'blog-images' 
       AND (auth.jwt() ->> 'email') = 'richardgtang@gmail.com'
     );
     ```

   **Is a public bucket safe?**  
   For this use case it is the right pragmatic choice. The images are *meant* to be public (they appear in your blog posts). The security comes from the RLS policies above, which ensure only your admin account (the same email check used for posts/tasks) can ever upload, modify, or delete files. A fully private bucket would require signed URLs that expire, which is painful for permanent blog content. This pattern (public bucket + admin-only upload policies) is the standard recommendation for personal/admin blogs in Supabase.

### After setup
- Open `admin.html` locally or on the deployed site.
- Log in with the email + password.
- You can now create/edit/publish blog posts and manage tasks.
- Published posts appear immediately on `blog.html`.

### Security model
- Row Level Security (RLS) is enabled on both tables.
- Public (anon) can only `SELECT` posts where `published = true`.
- All writes (and reading drafts) require the JWT email to match the single admin email you configured in the policies.
- The anon key is public by design (it's in the page source). The protection is the RLS policies + your password.

### Netlify
- Deploy is standard Git-based.
- No serverless functions are required for the current admin board (everything goes through the Supabase client + RLS).
- If you later want protected API routes or image uploads proxied, add a `netlify/functions/` directory and a `netlify.toml`.

## Content model

### posts
- `slug`, `title`, `content` (Markdown), `published`, `published_at`, `tags[]`
- Public list + detail views are rendered client-side with `marked`.

### tasks
- Private. `title`, `description` (Markdown), `status` (todo/doing/done), `priority`, `due_date`, `project`
- Used as a personal online task board.

## Adding a blog post from the admin
1. New Post
2. Write title (slug auto-generates, you can override)
3. Write Markdown in the editor (live preview on the right)
4. Toggle Published + Save
5. It appears on the public blog instantly.

## Styling philosophy
The site intentionally stays minimal (system fonts, restrained palette, very little JS on public surfaces). The admin page and blog reader necessarily add some JS and a bit more UI surface — they are intentionally scoped to those two pages.

## Future ideas
- Public "Now / Current projects" section fed from tasks with a `visible` flag
- RSS feed generation (static or edge function)
- Move to a tiny build step (Vite + SSG) if the client-side fetching ever becomes painful

Image uploads are already implemented (upload button in the admin editor → Supabase Storage `blog-images` bucket with the policies above). Uploaded images are stored under `posts/` and inserted as Markdown.

## License
Personal site. Do what you want with the code.
