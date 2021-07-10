import { Component, OnInit, Input, OnChanges, SimpleChanges } from '@angular/core';
import { SchoolService } from 'src/app/services/school.service';
import { Utils } from 'src/app/util/utils';
import { School, SchoolType } from 'src/app/interfaces/school';
import { SelectItem } from 'primeng/components/common/selectitem';
import { AppComponent } from 'src/app/app.component';
import { SchoolComponent } from '../school.component';

@Component({
  selector: 'app-school-detail',
  templateUrl: './school-detail.component.html',
  styleUrls: ['./school-detail.component.css']
})
export class SchoolDetailComponent implements OnInit, OnChanges {

  private mapper: Utils = new Utils();
  @Input() schoolId: number;
  school: School;
  schoolTypes: SelectItem[] = [];
  constructor(private schoolService: SchoolService, private app: AppComponent, private schoolComponent: SchoolComponent) { }


  ngOnChanges(changes: SimpleChanges): void {
    if (changes['schoolId'] && changes['schoolId'].currentValue != null) {
      this.loadSchoolInfo(changes['schoolId'].currentValue);
    } else {
      this.initSchool();
    }
  }

  ngOnInit() {

    this.loadSchoolTypes();
  }

  private initSchool(): void {
    this.school = {
      id: null,
      nome: '',
      tipologia: null
    };
  }

  private loadSchoolInfo(idSchool: number): void {
    this.schoolService.getSchool(idSchool).subscribe(res => {
      this.school = res[0];
    });
  }

  private loadSchoolTypes(): void {
    // tslint:disable-next-line: forin
    for (const st in SchoolType) {
      this.schoolTypes.push({
        value: st,
        label: st
      });
    }
  }

  public save(): void {
    if (this.schoolId != null) {
      this.updateSchool();
    } else {
      this.insertSchool();
    }
  }

  private updateSchool(): void {
    this.schoolService.updateSchool(this.school)
      .subscribe(
        res => {
          this.app.handleToastMessages('success', 'Completato', 'Scuola modificata');
          this.schoolComponent.displayDetailDialog = false;
        },
        error => {
          this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
        }
      );
  }

  private insertSchool(): void {
    this.schoolService.insertSchool(this.mapper.mapperSchoolToBeInserted(this.school)).subscribe(
      res => {
        this.app.handleToastMessages('success', 'Completato', 'Scuola creata');
        this.schoolComponent.displayDetailDialog = false;
      },
      error => {
        this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
      }
    );
  }

  // public onChangeCasaEditriveSelect(evt): void {
  //   this.school.casa_editrice = evt.value.id;
  // }

}
