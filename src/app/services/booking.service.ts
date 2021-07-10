import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class BookingService {
  private baseUrl = 'http://localhost:3000/';
  constructor(private http: HttpClient) { }

  public getBookingList(): Observable<any[]> {
    const url = this.baseUrl + 'v_prenotazioni';
    return this.http.get<any[]>(url);
  }

  getBookingsWithDetail(): Observable<any[]> {
    const url = this.baseUrl + 'prenotazioni?select=*,prenotazioni_studente(*)';
    return this.http.get<any[]>(url);
  }

  public getAllBooksForStudent(studentId: number): Observable<any[]> {
    const url = this.baseUrl + 'v_lista_libri?studente=eq.' + studentId;
    return this.http.get<any[]>(url);
  }

  public deleteBooking(id: number): Observable<any[]> {
    const url = this.baseUrl + 'prenotazioni?id=eq.' + id;
    return this.http.delete<any[]>(url);
  }

  public getBookingDetail(bookingId: number, studentId: number): Observable<any[]> {
    const url = this.baseUrl + 'prenotazioni_studente?studente=eq.' + studentId +
      '&prenotazione=eq.' + bookingId + '&select=*,studenti(*),libri(*,case_editrici(*)),prenotazioni(*)';
    return this.http.get<any[]>(url);
  }

  insertOrUpdateBookings(bookings: any[]): Observable<any> {
    const header: HttpHeaders = new HttpHeaders()
      .append('Prefer', 'resolution=merge-duplicates')
      .append('Content-Type', 'application/json');

    const body = JSON.stringify(bookings);
    return this.http.post<any>(this.baseUrl + 'prenotazioni_studente', body, { headers: header });
  }

  public updateBookingField(id: number, object) {
    const url = this.baseUrl + 'prenotazioni_studente?id=eq.' + id;
    const header: HttpHeaders = new HttpHeaders()
      .append('Prefer', 'resolution=merge-duplicates')
      .append('Content-Type', 'application/json');

    const body = JSON.stringify(object);
    return this.http.patch<any>(url, body, { headers: header });
  }

  insertBooking(booking: any): Observable<any> {
    const header: HttpHeaders = new HttpHeaders()
      .append('Prefer', 'return=representation')
      .append('Prefer', 'resolution=merge-duplicates')
      .set('Content-Type', 'application/json');

    const body = JSON.stringify(booking);
    return this.http.post<any>(this.baseUrl + 'prenotazioni', body, { headers: header });
  }
  public getBookingListByStudent(idStudent: number): Observable<any[]> {
    const url = this.baseUrl + 'v_prenotazioni?studente=eq.' + idStudent;
    return this.http.get<any[]>(url);
  }

  public getBookingsDetailByBookingId(bookingId: number): Observable<any[]> {
    const url = this.baseUrl + 'prenotazioni?id=eq.' + bookingId +
      '&select=*,prenotazioni_studente(*,libri(*,case_editrici(*)),studenti(*,classi(*,scuole(*))))';
    return this.http.get<any[]>(url);
  }
}
