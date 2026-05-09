import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../api/client';

interface User {
  id: number;
  login: string;
  email: string | null;
  full_name: string | null;
  role: string;
  is_active: boolean;
  odoo_user_id: number | null;
  ems_parent_id: number | null;
}

export function UsersPage() {
  const qc = useQueryClient();
  const { data, isLoading } = useQuery<User[]>({
    queryKey: ['users'],
    queryFn: async () => (await api.get('/admin/v1/users')).data,
  });

  const setRole = useMutation({
    mutationFn: ({ id, role }: { id: number; role: string }) =>
      api.post(`/admin/v1/users/${id}/role`, { role }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['users'] }),
  });
  const disable = useMutation({
    mutationFn: (id: number) => api.post(`/admin/v1/users/${id}/disable`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['users'] }),
  });

  if (isLoading) return <div>Loading…</div>;

  return (
    <div className="space-y-4">
      <h2 className="text-xl font-semibold">App users</h2>
      <table className="w-full bg-white border border-slate-200 rounded">
        <thead className="bg-slate-100 text-left text-sm">
          <tr>
            <th className="p-2">ID</th>
            <th className="p-2">Login</th>
            <th className="p-2">Name</th>
            <th className="p-2">Role</th>
            <th className="p-2">Odoo user</th>
            <th className="p-2">EMS parent</th>
            <th className="p-2">Active</th>
            <th className="p-2">Actions</th>
          </tr>
        </thead>
        <tbody className="text-sm">
          {(data ?? []).map((u) => (
            <tr key={u.id} className="border-t border-slate-100">
              <td className="p-2">{u.id}</td>
              <td className="p-2">{u.login}</td>
              <td className="p-2">{u.full_name ?? '—'}</td>
              <td className="p-2">
                <select
                  className="rounded border border-slate-300 px-2 py-1"
                  value={u.role}
                  onChange={(e) => setRole.mutate({ id: u.id, role: e.target.value })}
                >
                  {['parent', 'student', 'teacher', 'office', 'admin'].map((r) => (
                    <option key={r} value={r}>{r}</option>
                  ))}
                </select>
              </td>
              <td className="p-2">{u.odoo_user_id ?? '—'}</td>
              <td className="p-2">{u.ems_parent_id ?? '—'}</td>
              <td className="p-2">{u.is_active ? '✓' : '—'}</td>
              <td className="p-2">
                <button
                  className="rounded bg-red-600 px-3 py-1 text-white text-xs"
                  disabled={!u.is_active}
                  onClick={() => disable.mutate(u.id)}
                >
                  Disable
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
