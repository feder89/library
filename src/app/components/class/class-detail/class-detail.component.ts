import { Component, OnInit, Input, SimpleChanges, OnChanges } from '@angular/core';
import { ClassesService } from 'src/app/services/classes.service';
import { Class } from 'src/app/interfaces/class';
import { Utils } from 'src/app/util/utils';
import { SchoolService } from 'src/app/services/school.service';
import { AppComponent } from 'src/app/app.component';
import { ClassComponent } from '../class.component';
import { School } from 'src/app/interfaces/school';

@Component({
  selector: 'app-class-detail',
  templateUrl: './class-detail.component.html',
  styleUrls: ['./class-detail.component.css']
})
export class ClassDetailComponent implements OnInit, OnChanges {

  constructor(private classService: ClassesService,
    private schoolService: SchoolService,
    private app: AppComponent,
    private classComponent: ClassComponent) { }

  private mapper: Utils = new Utils();
  @Input() classId: number;
  class: Class;
  schools: School[] = [];
  ngOnChanges(changes: SimpleChanges): void {
    if (changes['classId'] && changes['classId'].currentValue != null) {
      this.loadClassInfo(changes['classId'].currentValue);
    } else {
      this.initClass();
    }
  }

  ngOnInit() {

    this.loadSchools();
  }

  initClass(): void {
    this.class = {
      id: null,
      nome: '',
      scuola: 0,
      scuole: null
    };
  }

  loadClassInfo(idClass: number): void {
    this.classService.getClass(idClass).subscribe(res => {
      this.class = res[0];
    });
  }

  loadSchools(): void {
    this.schoolService.getSchool().subscribe(res => {
      this.schools = res;
    });
  }

  save(): void {
    if (this.classId != null) {
      this.updateClass();
    } else {
      this.insertClass();
    }
  }

  updateClass(): void {
    this.classService.updateClass(this.mapper.mapperClassToDbObject(this.class))
      .subscribe(
        res => {
          this.app.handleToastMessages('success', 'Completato', 'Libro modificato');
          this.classComponent.displayDetailDialog = false;
        },
        error => {
          this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
        }
      );
  }

  insertClass(): void {
    this.classService.insertClass(this.mapper.mapperClassToDbObject(this.class)).subscribe(
      res => {
        this.app.handleToastMessages('success', 'Completato', 'Libro creato');
        this.classComponent.displayDetailDialog = false;
      },
      error => {
        this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
      }
    );
  }

  public onChangeSchoolSelect(evt): void {
    this.class.scuola = evt.value.id;
  }

}
