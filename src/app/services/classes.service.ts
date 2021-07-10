import { Injectable } from '@angular/core';
import { HttpHeaders, HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Class } from '../interfaces/class';
import { BookClassAssociation } from '../interfaces/book-class-association';

@Injectable({
  providedIn: 'root'
})
export class ClassesService {
  private baseUrl = 'http://localhost:3000/classi';

  constructor(private http: HttpClient) { }

  public getClass(id?: number): Observable<Class[]> {
    let url = 'http://localhost:3000/v_classi_ordinate';
    if (id != null) {
      url += '?id=eq.' + id;
    }

    return this.http.get<Class[]>(url);

  }

  public deleteClass(id: number): Observable<any> {
    const url = this.baseUrl + '?id=eq.' + id;

    return this.http.delete<any>(url);
  }

  public updateClass(book: Class): Observable<Class> {
    const url = this.baseUrl + '?id=eq.' + book.id;
    const header: HttpHeaders = new HttpHeaders({ 'Content-Type': 'application/json' });
    const body = JSON.stringify(book);
    return this.http.put<Class>(url, body, { headers: header });
  }

  public insertClass(book: Class): Observable<Class> {
    const header = new HttpHeaders({ 'Content-Type': 'application/json' });
    const body = JSON.stringify(book);
    return this.http.post<Class>(this.baseUrl, body, { headers: header });
  }

  public getBookAssociationByClassId(classId: number): Observable<any[]> {
    const url = 'http://localhost:3000/rpc/get_libri_associated_by_class_id?classid=' + classId;
    return this.http.get<any[]>(url);
  }

  public getBookNotAssociatedByClassId(classId: number): Observable<any[]> {
    const url = 'http://localhost:3000/rpc/get_libri_not_associated_by_class_id?classid=' + classId;
    return this.http.get<any[]>(url);
  }

  public deleteOldAssociations(bookId: number, classId: number): Observable<any> {
    const url = 'http://localhost:3000/libri_classe?id_libro=eq.' + bookId + '&id_classe=eq.' + classId;
    return this.http.delete<any>(url);
  }
  public createAssociations(bookId: number, classId: number): Observable<any> {
    const url = 'http://localhost:3000/libri_classe';
    const body = JSON.stringify({
      id_libro: bookId,
      id_classe: classId
    });
    const header: HttpHeaders = new HttpHeaders({ 'Content-Type': 'application/json' });

    return this.http.post<any>(url, body, { headers: header });
  }

  public getClassBySchhol(idSchool: number): Observable<any[]> {
    const url = this.baseUrl + '?scuola=eq.' + idSchool;
    return this.http.get<any[]>(url);
  }
}
