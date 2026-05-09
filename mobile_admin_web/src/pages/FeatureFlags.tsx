import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { api } from '../api/client';

interface Flag {
  key: string;
  value_bool: boolean;
  description: string | null;
}

export function FeatureFlagsPage() {
  const qc = useQueryClient();
  const { data } = useQuery<Flag[]>({
    queryKey: ['flags'],
    queryFn: async () => (await api.get('/admin/v1/feature-flags')).data,
  });
  const update = useMutation({
    mutationFn: (f: Flag) => api.put(`/admin/v1/feature-flags/${f.key}`, f),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['flags'] }),
  });
  const [newKey, setNewKey] = useState('');
  const [newDesc, setNewDesc] = useState('');

  return (
    <div className="space-y-4 max-w-3xl">
      <h2 className="text-xl font-semibold">Feature flags</h2>
      <div className="bg-white rounded border border-slate-200 divide-y">
        {(data ?? []).map((f) => (
          <div key={f.key} className="p-3 flex items-center justify-between">
            <div>
              <div className="font-mono text-sm">{f.key}</div>
              {f.description && <div className="text-xs text-slate-500">{f.description}</div>}
            </div>
            <label className="inline-flex items-center gap-2">
              <input
                type="checkbox"
                checked={f.value_bool}
                onChange={(e) => update.mutate({ ...f, value_bool: e.target.checked })}
              />
              <span className="text-sm">{f.value_bool ? 'On' : 'Off'}</span>
            </label>
          </div>
        ))}
      </div>
      <div className="bg-slate-100 p-4 rounded">
        <h3 className="font-medium">Add flag</h3>
        <div className="flex gap-2 mt-2">
          <input className="flex-1 rounded border border-slate-300 px-2 py-1" placeholder="feature.example"
                 value={newKey} onChange={(e) => setNewKey(e.target.value)} />
          <input className="flex-1 rounded border border-slate-300 px-2 py-1" placeholder="description"
                 value={newDesc} onChange={(e) => setNewDesc(e.target.value)} />
          <button className="rounded bg-slate-900 text-white px-3 py-1"
                  onClick={() => {
                    if (!newKey) return;
                    update.mutate({ key: newKey, value_bool: false, description: newDesc || null });
                    setNewKey(''); setNewDesc('');
                  }}>
            Add
          </button>
        </div>
      </div>
    </div>
  );
}
