import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Publisher } from '../interfaces/publisher';

@Injectable({
  providedIn: 'root'
})
export class PublisherService {
  private baseUrl = 'http://localhost:3000/case_editrici';
  constructor(private http: HttpClient) { }

  public getPublishers(id?: number): Observable<Publisher[]> {
    let url = this.baseUrl + '?order=nome';
    if (id != null) {
      url += '&id=eq.' + id;
    }

    return this.http.get<Publisher[]>(url);
  }

  public updatePublisher(el: Publisher): Observable<Publisher> {
    const url = this.baseUrl + '?id=eq.' + el.id;
    const body = JSON.stringify(el);
    const header: HttpHeaders = new HttpHeaders({ 'Content-Type': 'application/json' });
    return this.http.put<any>(url, body, { headers: header });

  }

  public createPublisher(el: Publisher): Observable<Publisher> {
    const body = JSON.stringify(el);
    const header: HttpHeaders = new HttpHeaders({ 'Content-Type': 'application/json' });
    return this.http.post<any>(this.baseUrl, body, { headers: header });

  }

  public deletePublisher(id: number): Observable<any> {
    const url = this.baseUrl + '?id=eq.' + id;
    return this.http.delete<any>(url);
  }
}
