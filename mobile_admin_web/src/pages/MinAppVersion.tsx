import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect, useState } from 'react';
import { api } from '../api/client';

interface VersionPayload {
  android: string;
  ios: string;
}

export function MinAppVersionPage() {
  const qc = useQueryClient();
  const { data } = useQuery<VersionPayload>({
    queryKey: ['min-app-version'],
    queryFn: async () => (await api.get('/admin/v1/min-app-version')).data,
  });
  const [android, setAndroid] = useState('1.0.0');
  const [ios, setIos] = useState('1.0.0');
  useEffect(() => {
    if (data) { setAndroid(data.android); setIos(data.ios); }
  }, [data]);

  const update = useMutation({
    mutationFn: (p: VersionPayload) => api.put('/admin/v1/min-app-version', p),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['min-app-version'] }),
  });

  return (
    <div className="space-y-4 max-w-md">
      <h2 className="text-xl font-semibold">Minimum app version</h2>
      <p className="text-sm text-slate-600">
        Devices below this version are forced to upgrade.
      </p>
      <div>
        <label className="block text-sm">Android</label>
        <input className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
               value={android} onChange={(e) => setAndroid(e.target.value)} />
      </div>
      <div>
        <label className="block text-sm">iOS</label>
        <input className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
               value={ios} onChange={(e) => setIos(e.target.value)} />
      </div>
      <button className="rounded bg-slate-900 text-white px-3 py-2"
              onClick={() => update.mutate({ android, ios })}>
        Save
      </button>
    </div>
  );
}
