import { useState } from "react";
import {
  useListMedicalRecords, useCreateMedicalRecord, useUpdateMedicalRecord,
  useListPatients, useListAppointments,
  getListMedicalRecordsQueryKey, useGetDoctorMe
} from "@workspace/api-client-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { useQueryClient } from "@tanstack/react-query";
import { Plus, FileText } from "lucide-react";
import { useAuth } from "@/lib/auth";

export default function MedicalRecordsPage() {
  const { role } = useAuth();
  const isDoctor = role === "DOCTOR";
  const isAdmin = role === "ADMIN";
  const [showDialog, setShowDialog] = useState(false);
  const [editingRecord, setEditingRecord] = useState<any>(null);
  const [selectedPatient, setSelectedPatient] = useState("all");
  const [form, setForm] = useState({ patientId: "", appointmentId: "", visitDate: "", diagnosis: "", notes: "" });
  const qc = useQueryClient();

  const { data: doctorMe } = useGetDoctorMe({ query: { queryKey: ["doctors", "me"], enabled: isDoctor } });
  const doctorId = isDoctor ? (doctorMe as any)?.doctorId : undefined;

  const { data: records, isLoading } = useListMedicalRecords({
    patientId: (selectedPatient && selectedPatient !== "all") ? Number(selectedPatient) : undefined,
    doctorId: doctorId,
  });

  const { data: patients } = useListPatients({ doctorId: isDoctor ? doctorId : undefined });
  const { data: appointments } = useListAppointments({ doctorId: isDoctor ? doctorId : undefined });

  const createMutation = useCreateMedicalRecord({
    mutation: {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: getListMedicalRecordsQueryKey() });
        setShowDialog(false);
        setEditingRecord(null);
        setForm({ patientId: "", appointmentId: "", visitDate: "", diagnosis: "", notes: "" });
      }
    }
  });

  const updateMutation = useUpdateMedicalRecord({
    mutation: {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: getListMedicalRecordsQueryKey() });
        setShowDialog(false);
        setEditingRecord(null);
        setForm({ patientId: "", appointmentId: "", visitDate: "", diagnosis: "", notes: "" });
      }
    }
  });

  const handleAppointmentSelect = (apptId: string) => {
    const appt = (appointments ?? []).find((a: any) => String(a.appointmentId) === apptId);
    if (appt) {
      setForm(f => ({ ...f, appointmentId: apptId, patientId: String((appt as any).patientId), visitDate: appt.dateTime ? new Date(appt.dateTime).toISOString().split("T")[0] : f.visitDate }));
    } else {
      setForm(f => ({ ...f, appointmentId: apptId }));
    }
  };

  const completedAppointments = (appointments ?? []).filter((a: any) => a.status === "CONFIRMED" || a.status === "COMPLETED");
  const availableAppointments = completedAppointments.filter((a: any) => !(records ?? []).some((r: any) => String(r.appointmentId) === String(a.appointmentId)));

  const openNew = () => {
    setEditingRecord(null);
    setForm({ patientId: "", appointmentId: "", visitDate: "", diagnosis: "", notes: "" });
    setShowDialog(true);
  };

  const openEdit = (r: any) => {
    setEditingRecord(r);
    setForm({
      patientId: String(r.patientId ?? ""),
      appointmentId: String(r.appointmentId ?? ""),
      visitDate: r.visitDate ?? "",
      diagnosis: r.diagnosis ?? "",
      notes: r.notes ?? "",
    });
    setShowDialog(true);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Medical Records</h1>
          <p className="text-muted-foreground">{isDoctor ? "Records from your patients" : "Patient medical history and records"}</p>
        </div>
        {isDoctor && <Button onClick={openNew} className="gap-2"><Plus className="w-4 h-4" /> New Record</Button>}
      </div>

      <div className="flex gap-3"><div className="w-64"><Select value={selectedPatient} onValueChange={setSelectedPatient}><SelectTrigger><SelectValue placeholder="Filter by patient..." /></SelectTrigger><SelectContent><SelectItem value="all">All Patients</SelectItem>{(patients ?? []).map((p: any) => (<SelectItem key={p.patientId} value={String(p.patientId)}>{p.name}</SelectItem>))}</SelectContent></Select></div></div>

      <div className="space-y-3">
        {isLoading && Array(3).fill(0).map((_, i) => (<Card key={i}><CardContent className="p-6"><Skeleton className="h-24 w-full" /></CardContent></Card>))}
        {!isLoading && (records ?? []).length === 0 && (<div className="text-center py-12 text-muted-foreground"><FileText className="w-12 h-12 mx-auto mb-3 opacity-30" /><p>No medical records found</p></div>)}
        {(records ?? []).map((r: any) => (
          <Card key={r.recordId} className="hover:shadow-md transition-shadow">
            <CardContent className="p-6">
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    <span className="font-semibold">{r.patientName}</span>
                    {isAdmin && (<><span className="text-muted-foreground text-sm">•</span><span className="text-muted-foreground text-sm">Dr. {r.doctorName}</span></>)}
                    <span className="text-muted-foreground text-sm">•</span><span className="text-muted-foreground text-sm">{r.visitDate}</span>
                  </div>
                  <p className="font-medium text-sm mb-1">Diagnosis:</p><p className="text-muted-foreground text-sm">{r.diagnosis}</p>
                  {r.notes && (<><p className="font-medium text-sm mt-2 mb-1">Notes:</p><p className="text-muted-foreground text-sm">{r.notes}</p></>)}
                </div>
                <div className="text-xs text-muted-foreground text-right"><p>Record #{r.recordId}</p>{r.appointmentId && <p>Appt #{r.appointmentId}</p>}</div>
              </div>
              {isDoctor && <div className="mt-4 flex justify-end"><Button variant="outline" size="sm" onClick={() => openEdit(r)}>Edit</Button></div>}
            </CardContent>
          </Card>
        ))}
      </div>

      {isDoctor && (<Dialog open={showDialog} onOpenChange={setShowDialog}><DialogContent className="max-w-lg"><DialogHeader><DialogTitle>{editingRecord ? "Edit Medical Record" : "New Medical Record"}</DialogTitle></DialogHeader><div className="space-y-4 py-4"><div className="space-y-2"><Label>Appointment <span className="text-destructive">*</span></Label><Select value={form.appointmentId} onValueChange={handleAppointmentSelect} disabled={!!editingRecord}><SelectTrigger><SelectValue placeholder="Select appointment..." /></SelectTrigger><SelectContent>{editingRecord ? completedAppointments.filter((a: any) => String(a.appointmentId) === form.appointmentId).map((a: any) => (<SelectItem key={a.appointmentId} value={String(a.appointmentId)}>#{a.appointmentId} — {a.patientName} ({new Date(a.dateTime).toLocaleDateString()})</SelectItem>)) : availableAppointments.map((a: any) => (<SelectItem key={a.appointmentId} value={String(a.appointmentId)}>#{a.appointmentId} — {a.patientName} ({new Date(a.dateTime).toLocaleDateString()})</SelectItem>))}</SelectContent></Select></div><div className="space-y-2"><Label>Patient</Label><Input value={form.patientId ? ((patients ?? []).find((p: any) => String(p.patientId) === form.patientId) as any)?.name ?? form.patientId : "Auto-filled from appointment"} disabled className="bg-muted" /></div><div className="space-y-2"><Label>Visit Date</Label><Input type="date" value={form.visitDate} onChange={e => setForm(f => ({ ...f, visitDate: e.target.value }))} /></div><div className="space-y-2"><Label>Diagnosis <span className="text-destructive">*</span></Label><Textarea value={form.diagnosis} onChange={e => setForm(f => ({ ...f, diagnosis: e.target.value }))} placeholder="Enter diagnosis..." /></div><div className="space-y-2"><Label>Notes (optional)</Label><Textarea value={form.notes} onChange={e => setForm(f => ({ ...f, notes: e.target.value }))} placeholder="Additional notes..." /></div></div><DialogFooter><Button variant="outline" onClick={() => setShowDialog(false)}>Cancel</Button><Button onClick={() => (editingRecord ? updateMutation.mutate({ id: editingRecord.recordId, data: { diagnosis: form.diagnosis, notes: form.notes || undefined } as any }) : createMutation.mutate({ data: { patientId: Number(form.patientId), doctorId: doctorId!, appointmentId: form.appointmentId ? Number(form.appointmentId) : undefined, visitDate: form.visitDate, diagnosis: form.diagnosis, notes: form.notes || undefined } as any }))} disabled={(editingRecord ? updateMutation.isPending : createMutation.isPending) || (!editingRecord && (!form.patientId || !form.visitDate || !form.diagnosis || !form.appointmentId))}>{editingRecord ? (updateMutation.isPending ? "Saving..." : "Update Record") : (createMutation.isPending ? "Saving..." : "Save Record")}</Button></DialogFooter></DialogContent></Dialog>)}
    </div>
  );
}
