import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Student } from '../interfaces/student';
import { HttpClient, HttpHeaders } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class StudentService {
  private baseUrl = 'http://localhost:3000/studenti';

  constructor(private http: HttpClient) { }

  getStudents(id?: number): Observable<Student[]> {
    let url = this.baseUrl + '?select=*,classi(*,scuole(*))';
    if (id != null) {
      url += '&id=eq.' + id;
    }

    return this.http.get<Student[]>(url);
  }

  public deleteStudent(id: number): Observable<any> {
    const url = this.baseUrl + '?id=eq.' + id;

    return this.http.delete<any>(url);
  }

  public updateStudent(student: Student): Observable<Student> {
    const url = this.baseUrl + '?id=eq.' + student.id;
    const header: HttpHeaders = new HttpHeaders({ 'Content-Type': 'application/json' });
    const body = JSON.stringify(student);
    return this.http.patch<Student>(url, body, { headers: header });
  }

  public insertStudent(student: Student): Observable<Student> {
    const header = new HttpHeaders({ 'Content-Type': 'application/json' })
      .append('Prefer', 'return=representation');
    const body = JSON.stringify(student);
    return this.http.post<Student>(this.baseUrl, body, { headers: header });
  }

  getStudentsDetail(classId: number): Observable<any[]> {
    const url = 'http://localhost:3000/v_studenti_dettagli?id_classe=eq.' + classId + '&order=cognome';
    return this.http.get<any[]>(url);
  }
}
