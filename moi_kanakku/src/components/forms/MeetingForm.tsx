import { useState, type FormEvent } from "react";
import { CalendarPlus, Video } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { company } from "@/data/company";
import { serviceOptions } from "@/data/services";

type Meeting = {
  service: string;
  date: string;
  time: string;
};

export function MeetingForm() {
  const [meeting, setMeeting] = useState<Meeting | null>(null);

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);
    const service = String(formData.get("service") || "Project discussion");
    const date = String(formData.get("date") || "Selected date");
    const time = String(formData.get("time") || "Selected time");
    setMeeting({ service, date, time });
  };

  if (meeting) {
    const calendarUrl = `https://calendar.google.com/calendar/render?action=TEMPLATE&text=${encodeURIComponent(`G.K Tech - ${meeting.service}`)}&details=${encodeURIComponent("Project meeting with G.K Tech")}`;

    return (
      <div className="rounded-lg border border-primary bg-primary/10 p-7">
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-accent">Meeting Confirmed</p>
        <h3 className="mt-4 font-display text-3xl font-semibold text-foreground">{meeting.service}</h3>
        <dl className="mt-5 grid gap-3 text-sm text-muted-foreground">
          <div className="flex justify-between gap-4"><dt>Date:</dt><dd className="text-foreground">{meeting.date}</dd></div>
          <div className="flex justify-between gap-4"><dt>Time:</dt><dd className="text-foreground">{meeting.time}</dd></div>
        </dl>
        <div className="mt-6 flex flex-wrap gap-3">
          <Button asChild className="rounded-full bg-primary text-primary-foreground">
            <a href={company.googleMeetUrl} target="_blank" rel="noreferrer"><Video aria-hidden="true" /> Join Meeting</a>
          </Button>
          <Button asChild variant="secondary" className="rounded-full">
            <a href={calendarUrl} target="_blank" rel="noreferrer"><CalendarPlus aria-hidden="true" /> Add to Google Calendar</a>
          </Button>
        </div>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="grid gap-4" aria-label="Book a meeting form">
      <select required name="service" aria-label="Select service" className="h-11 rounded-md border border-input bg-background px-3 text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-ring">
        <option value="">Select service</option>
        {serviceOptions.map((service) => <option key={service} value={service}>{service}</option>)}
      </select>
      <div className="grid gap-4 sm:grid-cols-2">
        <Input required type="date" name="date" aria-label="Preferred date" />
        <Input required type="time" name="time" aria-label="Preferred time" />
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <Input required name="name" placeholder="Name" aria-label="Name" />
        <Input required type="email" name="email" placeholder="Email" aria-label="Email" />
      </div>
      <Input required type="tel" name="phone" placeholder="Phone" aria-label="Phone" />
      <Textarea name="message" placeholder="Message" aria-label="Message" />
      <Button type="submit" className="h-12 rounded-full bg-primary text-primary-foreground">
        Book a Meeting <CalendarPlus aria-hidden="true" />
      </Button>
    </form>
  );
}
