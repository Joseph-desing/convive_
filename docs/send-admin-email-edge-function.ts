// Supabase Edge Function: send-admin-email
// Deploy path: supabase/functions/send-admin-email/index.ts
//
// Required secrets:
//   SUPABASE_URL
//   SUPABASE_SERVICE_ROLE_KEY
//   RESEND_API_KEY
// Optional:
//   ADMIN_EMAIL_FROM = "ConVive <notificaciones@tu-dominio.com>"

type RequestBody = {
  user_id?: string;
  email?: string;
  subject?: string;
  message?: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace("Bearer ", "");

    if (!jwt) {
      return json({ error: "No autorizado" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const resendApiKey = Deno.env.get("RESEND_API_KEY")!;
    const from =
      Deno.env.get("ADMIN_EMAIL_FROM") ??
      "ConVive <onboarding@resend.dev>";

    const authUserResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: {
        Authorization: `Bearer ${jwt}`,
        apikey: serviceKey,
      },
    });

    if (!authUserResponse.ok) {
      return json({ error: "Sesion invalida" }, 401);
    }

    const authUser = await authUserResponse.json();
    const adminResponse = await fetch(
      `${supabaseUrl}/rest/v1/users?id=eq.${authUser.id}&role=eq.admin&select=id`,
      {
        headers: {
          Authorization: `Bearer ${serviceKey}`,
          apikey: serviceKey,
        },
      },
    );
    const admins = await adminResponse.json();

    if (!Array.isArray(admins) || admins.length === 0) {
      return json({ error: "Solo administradores pueden enviar correos" }, 403);
    }

    const body = (await req.json()) as RequestBody;
    const email = body.email?.trim();
    const message = body.message?.trim();
    const subject =
      body.subject?.trim() || "ConVive - Notificacion de administracion";

    if (!email || !message) {
      return json({ error: "Falta email o mensaje" }, 400);
    }

    const emailResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from,
        to: email,
        subject,
        html: `
          <div style="margin:0; padding:0; background:#f6f7fb;">
            <div style="font-family: Arial, sans-serif; max-width: 620px; margin: 0 auto; padding: 28px 16px; color: #1f2937;">
              <div style="background: linear-gradient(135deg, #db2777, #ec4899); border-radius: 18px 18px 0 0; padding: 26px 28px;">
                <h1 style="margin: 0; color: #ffffff; font-size: 28px; line-height: 1.2;">ConVive</h1>
                <p style="margin: 8px 0 0; color: rgba(255,255,255,0.9); font-size: 14px;">
                  Notificacion importante de administracion
                </p>
              </div>

              <div style="background: #ffffff; border: 1px solid #eef0f4; border-top: 0; border-radius: 0 0 18px 18px; padding: 28px; box-shadow: 0 10px 28px rgba(15,23,42,0.08);">
                <p style="margin: 0 0 18px; font-size: 16px; line-height: 1.55;">
                  Hola, administracion de ConVive te ha enviado una notificacion sobre el estado de tu cuenta.
                </p>

                <div style="border: 1px solid #fecaca; background: #fef2f2; border-radius: 14px; padding: 18px; margin: 20px 0;">
                  <div style="color: #b91c1c; font-weight: 800; font-size: 14px; margin-bottom: 10px;">
                    Motivo de la notificacion
                  </div>
                  <p style="white-space: pre-line; margin: 0; color: #1f2937; font-size: 15px; line-height: 1.55;">
                    ${escapeHtml(message)}
                  </p>
                </div>

                <div style="background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 14px; padding: 18px; margin-top: 22px;">
                  <div style="font-weight: 800; color: #111827; margin-bottom: 10px;">Contacto de administracion</div>
                  <p style="margin: 6px 0; color: #4b5563; font-size: 14px;">
                    Correo: <a href="mailto:changoluizajoseph@gmail.com" style="color: #db2777; font-weight: 700; text-decoration: none;">changoluizajoseph@gmail.com</a>
                  </p>
                  <p style="margin: 6px 0; color: #4b5563; font-size: 14px;">
                    Celular: <a href="tel:+593983406747" style="color: #db2777; font-weight: 700; text-decoration: none;">0983406747</a>
                  </p>
                </div>

                <p style="margin: 22px 0 0; font-size: 12px; line-height: 1.5; color: #6b7280;">
                  Este correo fue enviado automaticamente por ConVive. Si consideras que se trata de un error, comunicate con administracion usando los datos anteriores.
                </p>
              </div>
            </div>
          </div>
        `,
      }),
    });

    const emailResult = await emailResponse.json();

    if (!emailResponse.ok) {
      return json({ error: "No se pudo enviar el email", detail: emailResult }, 502);
    }

    return json({ ok: true, result: emailResult }, 200);
  } catch (error) {
    return json({ error: String(error) }, 500);
  }
});

function json(data: unknown, status: number) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}
