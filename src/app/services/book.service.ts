import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Book } from '../interfaces/book';
import { HttpClient, HttpHeaders } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class BookService {
  private baseUrl = 'http://localhost:3000/libri';
  constructor(private http: HttpClient) { }

  public getBooks(id?: number, ordering?: string): Observable<Book[]> {
    let url = this.baseUrl + '?select=*,case_editrici(*)';
    if (id != null) {
      url += '&id=eq.' + id;
    }
    if (ordering) {
      url += '&order=' + ordering;
    } else {
      url += '&order=titolo';
    }

    return this.http.get<Book[]>(url);

  }

  public deleteBook(id: number): Observable<any> {
    const url = this.baseUrl + '?id=eq.' + id;

    return this.http.delete<any>(url);
  }

  public updateBook(book: Book): Observable<Book> {
    const url = this.baseUrl + '?id=eq.' + book.id;
    const header: HttpHeaders = new HttpHeaders({ 'Content-Type': 'application/json' });
    const body = JSON.stringify(book);
    return this.http.put<Book>(url, body, { headers: header });
  }

  public insertBook(book: Book): Observable<Book> {
    const header = new HttpHeaders({ 'Content-Type': 'application/json' });
    const body = JSON.stringify(book);
    return this.http.post<Book>(this.baseUrl, body, { headers: header });
  }
}
