import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api } from '../api/client';
import { useAuthStore } from '../store/auth';

export function LoginPage() {
  const [login, setLogin] = useState('admin@local');
  const [password, setPassword] = useState('admin');
  const [err, setErr] = useState<string | null>(null);
  const setTokens = useAuthStore((s) => s.setTokens);
  const navigate = useNavigate();

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setErr(null);
    try {
      const r = await api.post('/admin/v1/auth/login', { login, password });
      setTokens(r.data.access, r.data.refresh, r.data.user_id);
      navigate('/users');
    } catch (e: any) {
      setErr(e?.response?.data?.detail ?? 'Login failed');
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50">
      <form onSubmit={submit} className="w-96 space-y-4 bg-white p-8 rounded-xl shadow-sm border border-slate-200">
        <h1 className="text-xl font-semibold">Altatheeb Mobile Admin</h1>
        <p className="text-sm text-slate-500">
          Manage app users, feature flags, min app version, webhook deliveries and audit log.
        </p>
        <div>
          <label className="block text-sm">Login</label>
          <input className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                 value={login} onChange={(e) => setLogin(e.target.value)} />
        </div>
        <div>
          <label className="block text-sm">Password</label>
          <input className="mt-1 w-full rounded border border-slate-300 px-3 py-2" type="password"
                 value={password} onChange={(e) => setPassword(e.target.value)} />
        </div>
        {err && <p className="text-sm text-red-600">{err}</p>}
        <button className="w-full rounded bg-slate-900 px-3 py-2 text-white hover:bg-slate-800">
          Sign in
        </button>
      </form>
    </div>
  );
}
