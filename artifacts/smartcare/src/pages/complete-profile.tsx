import { useState } from "react";
import { useLocation } from "wouter";
import { useAuth } from "@/lib/auth";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { CheckCircle2, UserCircle } from "lucide-react";

export default function CompleteProfilePage() {
  const { user, token } = useAuth();
  const [, setLocation] = useLocation();
  const queryClient = useQueryClient();
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);

  const isPatient = user?.role === "PATIENT";
  const isDoctor = user?.role === "DOCTOR";

  const [patientForm, setPatientForm] = useState({
    gender: "",
    dateOfBirth: "",
    bloodType: "",
    address: "",
  });

  const [doctorForm, setDoctorForm] = useState({
    specialty: "",
    licenseNumber: "",
  });

  const { data: profile, isLoading } = useQuery({
    queryKey: ["my-profile", user?.userId],
    queryFn: async () => {
      const url = isPatient ? "/api/patients/me" : "/api/doctors/me";
      const res = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
      if (!res.ok) throw new Error("Failed to load profile");
      const data = await res.json();
      if (isPatient) {
        setPatientForm({
          gender: data.gender || "",
          dateOfBirth: data.dateOfBirth || "",
          bloodType: data.bloodType || "",
          address: data.address || "",
        });
      } else {
        setDoctorForm({
          specialty: data.specialty || "",
          licenseNumber: data.licenseNumber || "",
        });
      }
      return data;
    },
    enabled: !!token && (isPatient || isDoctor),
  });

  const mutation = useMutation({
    mutationFn: async () => {
      const id = isPatient ? profile?.patientId : profile?.doctorId;
      const url = isPatient ? `/api/patients/${id}` : `/api/doctors/${id}`;
      const body = isPatient ? patientForm : doctorForm;
      const res = await fetch(url, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(body),
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error((err as any).message || "Failed to save profile");
      }
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["my-profile"] });
      queryClient.invalidateQueries({ queryKey: ["profile-complete"] });
      setSuccess(true);
      setTimeout(() => setLocation("/dashboard"), 1500);
    },
    onError: (err: any) => {
      setError(err.message || "Failed to save profile");
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    if (isPatient && !patientForm.gender) {
      setError("Gender is required.");
      return;
    }
    if (isDoctor && (!doctorForm.specialty || !doctorForm.licenseNumber)) {
      setError("Specialty and license number are required.");
      return;
    }
    mutation.mutate();
  };

  if (!isPatient && !isDoctor) {
    return (
      <div className="max-w-lg mx-auto mt-10">
        <p className="text-muted-foreground">Profile completion is not required for your role.</p>
      </div>
    );
  }

  return (
    <div className="max-w-lg mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold flex items-center gap-2">
          <UserCircle className="w-6 h-6 text-primary" />
          Complete Your Profile
        </h1>
        <p className="text-muted-foreground mt-1">
          Fill in your details to get full access to SmartCare.
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>{isPatient ? "Patient Information" : "Doctor Information"}</CardTitle>
          <CardDescription>
            {isPatient
              ? "Fields marked with * are required."
              : "Your specialty and license number are required."}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {success ? (
            <div className="flex flex-col items-center gap-3 py-8 text-center">
              <CheckCircle2 className="w-12 h-12 text-green-500" />
              <p className="text-lg font-semibold">Profile saved!</p>
              <p className="text-muted-foreground text-sm">Redirecting to dashboard…</p>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-4">
              {error && (
                <Alert variant="destructive">
                  <AlertDescription>{error}</AlertDescription>
                </Alert>
              )}

              {isPatient && (
                <>
                  <div className="space-y-2">
                    <Label htmlFor="gender">Gender *</Label>
                    <Select
                      value={patientForm.gender}
                      onValueChange={(v) => setPatientForm((f) => ({ ...f, gender: v }))}
                    >
                      <SelectTrigger id="gender">
                        <SelectValue placeholder="Select gender" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="Male">Male</SelectItem>
                        <SelectItem value="Female">Female</SelectItem>
                        <SelectItem value="Other">Other</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="dob">Date of Birth</Label>
                    <Input
                      id="dob"
                      type="date"
                      value={patientForm.dateOfBirth}
                      onChange={(e) => setPatientForm((f) => ({ ...f, dateOfBirth: e.target.value }))}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="blood">Blood Type</Label>
                    <Select
                      value={patientForm.bloodType}
                      onValueChange={(v) => setPatientForm((f) => ({ ...f, bloodType: v }))}
                    >
                      <SelectTrigger id="blood">
                        <SelectValue placeholder="Select blood type" />
                      </SelectTrigger>
                      <SelectContent>
                        {["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"].map((bt) => (
                          <SelectItem key={bt} value={bt}>{bt}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="address">Address</Label>
                    <Input
                      id="address"
                      placeholder="Your home address"
                      value={patientForm.address}
                      onChange={(e) => setPatientForm((f) => ({ ...f, address: e.target.value }))}
                    />
                  </div>
                </>
              )}

              {isDoctor && (
                <>
                  <div className="space-y-2">
                    <Label htmlFor="specialty">Specialty *</Label>
                    <Input
                      id="specialty"
                      placeholder="e.g. Cardiology"
                      value={doctorForm.specialty}
                      onChange={(e) => setDoctorForm((f) => ({ ...f, specialty: e.target.value }))}
                      required
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="license">License Number *</Label>
                    <Input
                      id="license"
                      placeholder="e.g. LIC-00123"
                      value={doctorForm.licenseNumber}
                      onChange={(e) => setDoctorForm((f) => ({ ...f, licenseNumber: e.target.value }))}
                      required
                    />
                  </div>
                </>
              )}

              <div className="flex gap-3 pt-2">
                <Button type="button" variant="outline" onClick={() => setLocation("/dashboard")}>
                  Do it later
                </Button>
                <Button type="submit" className="flex-1" disabled={mutation.isPending || isLoading}>
                  {mutation.isPending ? "Saving…" : "Save Profile"}
                </Button>
              </div>
            </form>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
