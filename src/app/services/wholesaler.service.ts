import { Injectable } from '@angular/core';
import { HttpHeaders, HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Wholesaler } from '../interfaces/wholesaler';

@Injectable({
  providedIn: 'root'
})
export class WholesalerService {
  private header: HttpHeaders = new HttpHeaders({ 'Content-Type': 'application/json' });
  private baseUrl = 'http://localhost:3000/distributore';

  constructor(private http: HttpClient) { }

  public getWholesalers(id?: number): Observable<Wholesaler[]> {
    let url = this.baseUrl + '?order=nome';
    if (id != null) {
      url += '&id=eq.' + id;
    }

    return this.http.get<Wholesaler[]>(url);
  }

  public updateWholesaler(el: Wholesaler): Observable<Wholesaler> {
    const url = this.baseUrl + '?id=eq.' + el.id;
    const body = JSON.stringify(el);
    const header: HttpHeaders = new HttpHeaders({ 'Content-Type': 'application/json' });
    return this.http.put<any>(url, body, { headers: header });

  }

  public createWholesaler(el: Wholesaler): Observable<Wholesaler> {
    const body = JSON.stringify(el);
    const header: HttpHeaders = new HttpHeaders({ 'Content-Type': 'application/json' });
    return this.http.post<any>(this.baseUrl, body, { headers: header });

  }

  public deleteWholesaler(id: number): Observable<any> {
    const url = this.baseUrl + '?id=eq.' + id;
    return this.http.delete<any>(url);
  }
}
