import { Component, OnInit } from '@angular/core';
import { SchoolService } from 'src/app/services/school.service';
import { MessageService } from 'primeng/components/common/messageservice';
import { School } from 'src/app/interfaces/school';
import { AppComponent } from 'src/app/app.component';

@Component({
  selector: 'app-school',
  templateUrl: './school.component.html',
  styleUrls: ['./school.component.css']
})
export class SchoolComponent implements OnInit {
  public schools: School[];
  public totalSchools: School[];
  public displayDetailDialog: boolean;
  public schoolIdSeleted: number = null;
  public type: string = null;
  public value: string = null;
  private idToDelete: number = 0;


  constructor(private schoolService: SchoolService, private messageService: MessageService, private app: AppComponent) { }

  ngOnInit() {
    this.getAllSchools();
  }

  private getAllSchools() {
    this.schoolService.getSchool().subscribe(
      (res: School[]) => {
        this.schools = res;
        this.totalSchools = res;
      }
    );
  }

  closeDialog(): void {
    this.getAllSchools();
    this.schoolIdSeleted = null;
  }

  onSelectSchool(id: number): void {
    this.schoolIdSeleted = id;
    this.displayDetailDialog = true;
  }

  onDeleteSchool(id: number, nome: string): void {
    this.idToDelete = id;
    this.value = nome;
    this.type = "Scuola";

  }

  onAddSchool(): void {
    this.displayDetailDialog = true;
  }

  public filterSchools(s: string) {
    this.schools = this.totalSchools.filter((b) => {
      return b.nome.toLowerCase().indexOf(s) > -1;
    });
  }

  confirmDelete(evt) {
    if (evt == true) {
      this.schoolService.deleteSchool(this.idToDelete).subscribe(
        res => {
          this.app.handleToastMessages('success', 'Completato', 'Scuola rimossa');
          this.getAllSchools();
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
