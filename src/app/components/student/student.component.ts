import { Component, OnInit } from '@angular/core';
import { Student } from 'src/app/interfaces/student';
import { StudentService } from 'src/app/services/student.service';
import { AppComponent } from 'src/app/app.component';

@Component({
  selector: 'app-student',
  templateUrl: './student.component.html',
  styleUrls: ['./student.component.css']
})
export class StudentComponent implements OnInit {
  public students: Student[];
  public totalStudents: Student[];
  public displayDetailDialog: boolean;
  public studentIdSeleted: number = null;
  public type: string = null;
  public value: string = null;
  private idToDelete: number = 0;

  constructor(private studentService: StudentService, private app: AppComponent) { }

  ngOnInit() {
    this.getAllStudents();
  }

  private getAllStudents() {
    this.studentService.getStudents().subscribe(
      (res: Student[]) => {
        this.students = res;
        this.totalStudents = res;
      }
    );
  }

  closeDialog(): void {
    this.getAllStudents();
    this.studentIdSeleted = null;
  }

  onSelectStudent(id: number): void {
    this.studentIdSeleted = id;
    this.displayDetailDialog = true;
  }

  onDeleteStudent(id: number, nome: string): void {
    this.value = nome;
    this.idToDelete = id;
    this.type = "Studente";    
  }

  onAddStudent(): void {
    this.studentIdSeleted = null;
    this.displayDetailDialog = true;
  }

  public closeStudentDetails(event): void {
    this.displayDetailDialog = false;
  }

  public filterStudents(s: string) {
    this.students = this.totalStudents.filter((b) => {
      return b.cognome.toLowerCase().indexOf(s) > -1;
    });
  }

  confirmDelete(evt) {
    if (evt == true) {
      this.studentService.deleteStudent(this.idToDelete).subscribe(
        res => {
          this.app.handleToastMessages('success', 'Completato', 'Studente rimosso');
          this.getAllStudents();
        },
        error => {
          this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
        }
      );
    }
    this.value = null;
    this.idToDelete = 0;
    this.type = null;
  }
}
