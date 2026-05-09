import { Link, NavLink, Outlet } from 'react-router-dom';
import { useAuthStore } from '../store/auth';

const linkClass = ({ isActive }: { isActive: boolean }) =>
  `block rounded px-3 py-2 text-sm ${
    isActive ? 'bg-slate-900 text-white' : 'text-slate-700 hover:bg-slate-200'
  }`;

export function Shell() {
  const logout = useAuthStore((s) => s.logout);
  return (
    <div className="min-h-screen flex">
      <aside className="w-64 bg-slate-100 border-r border-slate-200 p-4 flex flex-col">
        <Link to="/" className="font-semibold text-lg mb-6">
          Altatheeb Admin
        </Link>
        <nav className="space-y-1 flex-1">
          <NavLink to="/users" className={linkClass}>App users</NavLink>
          <NavLink to="/feature-flags" className={linkClass}>Feature flags</NavLink>
          <NavLink to="/min-app-version" className={linkClass}>Min app version</NavLink>
          <NavLink to="/webhook-deliveries" className={linkClass}>Webhook deliveries</NavLink>
          <NavLink to="/audit" className={linkClass}>Audit log</NavLink>
        </nav>
        <button
          onClick={logout}
          className="mt-4 rounded bg-slate-900 px-3 py-2 text-sm text-white hover:bg-slate-800"
        >
          Sign out
        </button>
      </aside>
      <main className="flex-1 p-6 overflow-auto">
        <Outlet />
      </main>
    </div>
  );
}
