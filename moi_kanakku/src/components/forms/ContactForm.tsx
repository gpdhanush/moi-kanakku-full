import { useState, type FormEvent } from "react";
import { Send } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { serviceOptions } from "@/data/services";

export function ContactForm() {
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmitted(true);
  };

  if (submitted) {
    return (
      <div className="rounded-lg border border-primary bg-primary/10 p-8">
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-accent">Enquiry sent</p>
        <h3 className="mt-4 font-display text-3xl font-semibold text-foreground">Thank you. G.K Tech will contact you shortly.</h3>
        <p className="mt-4 leading-7 text-muted-foreground">Your project details are saved in this session preview. Backend delivery can connect this form to an API later.</p>
        <Button type="button" className="mt-6 rounded-full" onClick={() => setSubmitted(false)}>Send another enquiry</Button>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="grid gap-4" aria-label="Contact enquiry form">
      <div className="grid gap-4 sm:grid-cols-2">
        <Input required name="name" placeholder="Name" aria-label="Name" />
        <Input name="company" placeholder="Company" aria-label="Company" />
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <Input required type="email" name="email" placeholder="Email" aria-label="Email" />
        <Input required type="tel" name="phone" placeholder="Phone" aria-label="Phone" />
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <select required name="service" aria-label="Service" className="h-11 rounded-md border border-input bg-background px-3 text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-ring">
          <option value="">Service</option>
          {serviceOptions.map((service) => <option key={service} value={service}>{service}</option>)}
        </select>
        <select name="projectType" aria-label="Project type" className="h-11 rounded-md border border-input bg-background px-3 text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-ring">
          <option value="">Project type</option>
          <option>New project</option>
          <option>Existing project improvement</option>
          <option>Maintenance and support</option>
          <option>Product development</option>
        </select>
      </div>
      <select name="budget" aria-label="Budget" className="h-11 rounded-md border border-input bg-background px-3 text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-ring">
        <option value="">Budget</option>
        <option>Under ₹50,000</option>
        <option>₹50,000 - ₹1,50,000</option>
        <option>₹1,50,000 - ₹5,00,000</option>
        <option>₹5,00,000+</option>
      </select>
      <Textarea required name="message" placeholder="Tell us about your idea" aria-label="Message" className="min-h-32" />
      <Input type="file" name="attachment" aria-label="Attachment" />
      <Button type="submit" className="h-12 rounded-full bg-primary text-primary-foreground">
        Send Enquiry <Send aria-hidden="true" />
      </Button>
    </form>
  );
}
