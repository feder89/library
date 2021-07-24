import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class OrderService {
  private baseUrl = 'http://localhost:3000/';
  constructor(private http: HttpClient) { }

  public getOrders(id?: number): Observable<any[]> {
    let url = this.baseUrl + 'v_ordini_object?order=data';
    if (id != null) {
      url += '&id=eq.' + id;
    }

    return this.http.get<any[]>(url);
  }

  public deleteOrder(id: number): Observable<any> {
    const url = this.baseUrl + 'ordini' + '?id=eq.' + id;

    return this.http.delete<any>(url);
  }

  insertOrUpdateOrders(order: any): Observable<any> {
    const header: HttpHeaders = new HttpHeaders()
      .append('Prefer', 'return=representation')
      .append('Prefer', 'resolution=merge-duplicates')
      .append('Content-Type', 'application/json');

    const body = JSON.stringify(order);
    return this.http.post<any>(this.baseUrl + 'ordini', body, { headers: header });
  }

  insertOrUpdateBookingOrder(object: any[]): Observable<any> {
    const header: HttpHeaders = new HttpHeaders()
      .append('Prefer', 'resolution=merge-duplicates')
      .append('Prefer', 'return=representation')
      .append('Content-Type', 'application/json');

    const body = JSON.stringify(object);
    return this.http.post<any>(this.baseUrl + 'ordine_prenotazioni', body, { headers: header });
  }

  public getBookingNotInWaiting(): Observable<any[]> {
    const url = this.baseUrl + 'rpc/get_bookings_nor_in_waiting';
    return this.http.get<any[]>(url);
  }

  public getWaitingBookings(): Observable<any[]> {
    const url = this.baseUrl + 'v_prenotazioni_in_attesa';
    return this.http.get<any[]>(url);
  }

  public getWaitingBooks(): Observable<any[]> {
    const url = this.baseUrl + 'v_libri_in_attesa';
    return this.http.get<any[]>(url);
  }

  public getArrivedOrdersByStudent(): Observable<any[]> {
    const url = this.baseUrl + 'v_libri_arrivati_studente';
    return this.http.get<any[]>(url);
  }

  public getBookForOrder(idOrder): Observable<any[]> {
    const url = this.baseUrl + 'v_libri_per_ordine?id_ordine=eq.' + idOrder;

    return this.http.get<any[]>(url);
  }

  public updateProtocolOrder(id, obj: any): Observable<any> {
    const header: HttpHeaders = new HttpHeaders()
      .append('Content-Type', 'application/json');
    const url = this.baseUrl + 'ordini?id=eq.' + id;
    const body = JSON.stringify(obj);
    return this.http.patch<any>(url, body, { headers: header });
  }

  public getOrdersToBeReminded(id: number, type: string): Observable<any[]> {
    const url = this.baseUrl + 'rpc/filtra_ordini_by_id_and_tipo?_id=' + id + '&_tipo=' + type;
    return this.http.get<any[]>(url);
  }

  public getWholsalersAndPublisherToBeReminded(): Observable<any[]> {
    const url = this.baseUrl + 'rpc/filtra_ordini_all';
    return this.http.get<any[]>(url);
  }

  public updateOrderBookingsToWaitingStatus(id_ordine: number): Observable<any> {    
    const header: HttpHeaders = new HttpHeaders()
      .append('Content-Type', 'application/json');
    const bosy = JSON.stringify({orderid:id_ordine});
    let url = this.baseUrl + 'rpc/update_ordini_in_attesa';
    return this.http.post<any>(url, bosy, {headers: header});
  }

}
