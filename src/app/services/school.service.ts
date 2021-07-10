import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { School } from '../interfaces/school';

@Injectable({
  providedIn: 'root'
})
export class SchoolService {

  private header: HttpHeaders = new HttpHeaders({ 'Content-Type': 'application/json' });
  private baseUrl = 'http://localhost:3000/scuole';

  constructor(private http: HttpClient) { }

  public getSchool(id?: number): Observable<School[]> {
    let url = this.baseUrl + '?order=nome';
    if (id != null) {
      url += '&id=eq.' + id;
    }

    return this.http.get<School[]>(url);
  }

  public insertSchool(el: School): Observable<any> {
    const body = JSON.stringify(el);
    return this.http.post<any>(this.baseUrl, body, { headers: this.header });
  }

  public updateSchool(el: School): Observable<any> {
    const body = JSON.stringify(el);
    const url = this.baseUrl + '?id=eq.' + el.id;
    return this.http.put<any>(url, body, { headers: this.header });
  }

  public deleteSchool(id: number): Observable<any> {
    const url = this.baseUrl + '?id=eq.' + id;
    return this.http.delete<any>(url);
  }
}
