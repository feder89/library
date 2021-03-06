import { Component, OnInit } from '@angular/core';
import { ClassesService } from 'src/app/services/classes.service';
import { AppComponent } from 'src/app/app.component';
import { Class } from 'src/app/interfaces/class';

@Component({
  selector: 'app-class',
  templateUrl: './class.component.html',
  styleUrls: ['./class.component.css']
})
export class ClassComponent implements OnInit {
  public classes: Class[];
  public allClasses: Class[];
  public displayDetailDialog: boolean;
  public classIdSeleted: number = null;
  public classIdSeletedAssociation: number = null;
  public displayAssociationDialog: boolean;
  public type: string = null;
  public value: string = null;
  private idToDelete: number = 0;

  constructor(private classService: ClassesService, private app: AppComponent) { }

  ngOnInit() {
    this.getAllClasss();
  }

  private getAllClasss() {
    this.classService.getClass().subscribe(
      (res: Class[]) => {
        this.classes = res;
        this.allClasses = res;
      }
    );
  }

  public closeDialog(evt): void {
    this.getAllClasss();
    this.classIdSeleted = null;
  }

  public closeAssociationDialog(evt): void {
    this.classIdSeletedAssociation = null;
    this.displayAssociationDialog = false;
  }

  public onSelectClass(id: number): void {
    this.classIdSeleted = id;
    this.displayDetailDialog = true;
  }

  public onSelectClassAssociation(id: number): void {
    this.classIdSeletedAssociation = id;
    this.displayAssociationDialog = true;
  }

  public onDeleteClass(id: number, nome: string): void {
    this.idToDelete = id;
    this.value = nome;
    this.type = "Classe";

  }

  public onAddClass(): void {
    this.displayDetailDialog = true;
  }

  public filterClass(s: string) {
    this.classes = this.allClasses.filter((c) => {
      return c.nome.toLowerCase().indexOf(s) > -1;
    })
  }

  confirmDelete(evt) {
    if (evt == true) {
      this.classService.deleteClass(this.idToDelete).subscribe(
        res => {
          this.app.handleToastMessages('success', 'Completato', 'Libro rimosso');
          this.getAllClasss();
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
