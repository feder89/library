import { Component, OnInit } from '@angular/core';
import { StudentService } from 'src/app/services/student.service';
import { SchoolService } from 'src/app/services/school.service';
import { ClassesService } from 'src/app/services/classes.service';
import { SelectItem } from 'primeng/api';

@Component({
  selector: 'app-students-for-class',
  templateUrl: './students-for-class.component.html',
  styleUrls: ['./students-for-class.component.css']
})
export class StudentsForClassComponent implements OnInit {
  public allSchool: SelectItem[];
  public classes: SelectItem[];
  public students: any[];
  constructor(
    private studentService: StudentService,
    private schoolService: SchoolService,
    private classService: ClassesService
  ) { }

  ngOnInit() {
    this.loadSchools();
  }

  private loadSchools() {
    this.schoolService.getSchool()
      .subscribe(
        res => {
          this.allSchool = [];
          res.forEach(s => {
            this.allSchool.push({
              label: s.nome + ' - ' + s.tipologia,
              value: s.id
            });
          });
        }
      );
  }

  public onChangeSchool(evt) {
    this.classService.getClassBySchhol(evt.value).subscribe(
      res => {
        this.classes = [];
        res.forEach(c => {
          this.classes.push({
            label: c.nome,
            value: c.id
          });
        });
      }
    );
  }
  public onChangeClass(evt) {
    this.studentService.getStudentsDetail(evt.value).subscribe(
      res => {
        this.students = [];
        res.forEach(c => {
          this.students.push({
            nome: c.nome,
            cognome: c.cognome
          });
        });
      }
    );
  }

}
