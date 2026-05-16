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
          <div style="font-family: Arial, sans-serif; max-width: 560px; margin: 0 auto; color: #1f2937;">
            <h2 style="color: #db2777;">ConVive</h2>
            <p>Administracion te ha enviado una notificacion sobre tu cuenta.</p>
            <div style="border: 1px solid #fecaca; background: #fef2f2; border-radius: 12px; padding: 16px; margin: 18px 0;">
              <strong style="color: #b91c1c;">Motivo:</strong>
              <p style="white-space: pre-line; margin-bottom: 0;">${escapeHtml(message)}</p>
            </div>
            <p style="font-size: 13px; color: #6b7280;">
              Si tienes dudas, contacta al equipo de administracion de ConVive.
            </p>
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
