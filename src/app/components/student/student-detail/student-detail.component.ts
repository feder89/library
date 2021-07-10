import { Component, EventEmitter, Input, OnChanges, Output, SimpleChanges } from '@angular/core';
import { SelectItem } from 'primeng/components/common/selectitem';
import { AppComponent } from 'src/app/app.component';
import { Student } from 'src/app/interfaces/student';
import { ClassesService } from 'src/app/services/classes.service';
import { StudentService } from 'src/app/services/student.service';
import { Utils } from 'src/app/util/utils';

@Component({
  selector: 'app-student-detail',
  templateUrl: './student-detail.component.html',
  styleUrls: ['./student-detail.component.css']
})
export class StudentDetailComponent implements OnChanges {

  constructor(private classService: ClassesService,
    private app: AppComponent,
    private studentService: StudentService) { }

  private mapper: Utils = new Utils();
  @Input() studentId: number;
  @Output() close: EventEmitter<any> = new EventEmitter();
  student: Student;
  classes: SelectItem[] = [];
  ngOnChanges(changes: SimpleChanges): void {
    if (changes['studentId'] && changes['studentId'].currentValue != null) {
      this.loadStudentInfo(changes['studentId'].currentValue);
    } else {
      this.initStudent();
    }
    this.loadSchools();
  }


  initStudent(): void {
    this.student = this.mapper.mapperStudentToDbObject({
      id: null,
      nome: '',
      cognome: '',
      residenza: '',
      classe: null,
      mail: '',
      telefono: '',
      classi: null
    });
  }

  loadStudentInfo(idStudent: number): void {
    this.studentService.getStudents(idStudent).subscribe(res => {
      this.student = this.mapper.mapperStudentToDbObject(res[0]);
    });
  }

  loadSchools(): void {
    this.classService.getClass().subscribe(res => {
      this.classes = [];
      res.forEach(el => {
        this.classes.push({
          value: el.id,
          label: el.scuole.nome + ' - ' + el.nome
        });
      });
    });
  }

  save(): void {
    if (this.studentId != null) {
      this.updateStudent();
    } else {
      this.insertStudent();
    }
  }

  updateStudent(): void {
    this.studentService.updateStudent(this.student)
      .subscribe(
        res => {
          this.app.handleToastMessages('success', 'Completato', 'Studente modificato');
          this.close.emit(true);
          // this.studentComponent.displayDetailDialog = false;
          // this.bookingDetailComponent.displayStudentDetail = false;
        },
        error => {
          this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
        }
      );
  }

  insertStudent(): void {
    this.studentService.insertStudent(this.student).subscribe(
      res => {
        this.app.handleToastMessages('success', 'Completato', 'Studente creato');
        this.close.emit({ student: res[0].id, class: res[0].classe });
        // this.studentComponent.displayDetailDialog = false;
        // this.bookingDetailComponent.displayStudentDetail = false;
      },
      error => {
        this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
      }
    );
  }

}
