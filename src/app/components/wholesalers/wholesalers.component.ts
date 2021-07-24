import { Component, OnInit } from '@angular/core';
import { WholesalerService } from 'src/app/services/wholesaler.service';
import { Wholesaler } from 'src/app/interfaces/wholesaler';
import { AppComponent } from 'src/app/app.component';

@Component({
  selector: 'app-wholesalers',
  templateUrl: './wholesalers.component.html',
  styleUrls: ['./wholesalers.component.css']
})
export class WholesalersComponent implements OnInit {

  public wholesalers: Wholesaler[];
  public totalWholesalers: Wholesaler[];
  public displayDetailDialog: boolean;
  public wholesalerIdSeleted: number = null;
  public type: string = null;
  public value: string = null;
  private idToDelete: number = 0;

  constructor(private wholesalerService: WholesalerService, private app: AppComponent) { }

  ngOnInit() {
    this.loadWholesaler();
  }

  private loadWholesaler(): void {
    this.wholesalerService.getWholesalers().subscribe(
      res => {
        this.wholesalers = res;
        this.totalWholesalers = res;
      }
    );
  }

  public onAddWholesaler(): void {
    this.displayDetailDialog = true;
  }

  public onSelectWholesaler(el: number): void {
    this.wholesalerIdSeleted = el;
    this.displayDetailDialog = true;
  }

  public onDeleteWholesaler(el: number, nome: string): void {
    this.value = nome;
    this.idToDelete = el;
    this.type = "Distributore";
  }

  public closeDialog(): void {
    this.loadWholesaler();
    this.wholesalerIdSeleted = null;
  }

  public filterPublishers(s: string) {
    this.wholesalers = this.totalWholesalers.filter((b) => {
      return b.nome.toLowerCase().indexOf(s) > -1;
    })
  }

  confirmDelete(evt) {
    if (evt == true) {
      this.wholesalerService.deleteWholesaler(this.idToDelete)
        .subscribe(
          res => {
            this.app.handleToastMessages('success', 'Completato', 'Libro rimosso');
            this.loadWholesaler();
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
