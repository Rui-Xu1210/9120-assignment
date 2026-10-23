-- Read-only evidence for the coursework demonstration. Run in your demo database.
SELECT p.name AS parent_name,
       c.name AS child_name,
       v.vaccine_name,
       i.dose_number,
       s.scheduled_date,
       s.status AS schedule_status,
       r.reminder_date,
       r.reminder_status,
       d.vaccination_date,
       d.provider
FROM parent p
JOIN child c ON c.parent_id=p.parent_id
JOIN vaccine_schedule_id i ON i.child_id=c.child_id
JOIN vaccine v ON v.vaccine_id=i.vaccine_id
JOIN vaccine_schedule s ON s.schedule_id=i.schedule_id
LEFT JOIN vaccine_reminder r ON r.schedule_id=i.schedule_id
LEFT JOIN vaccine_record d ON d.child_id=i.child_id AND d.vaccine_id=i.vaccine_id AND d.dose_number=i.dose_number
ORDER BY c.child_id,s.scheduled_date,v.vaccine_name,i.dose_number;
