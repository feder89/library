import { Component, OnInit } from '@angular/core';
import { AppComponent } from 'src/app/app.component';
import { Status } from 'src/app/interfaces/status.enum';
import { OrderService } from 'src/app/services/order.service';
import { Utils } from 'src/app/util/utils';

@Component({
  selector: 'app-order-manager',
  templateUrl: './order-manager.component.html',
  styleUrls: ['./order-manager.component.css']
})
export class OrderManagerComponent implements OnInit {
  public orders: any[];
  public displayDetailDialog: boolean;
  public orderIdSeleted: number = null;
  public utils: Utils = new Utils();
  public type: string = null;
  public value: string = null;
  private idToDelete: number = 0;

  constructor(private orderService: OrderService, private app: AppComponent) { }

  ngOnInit() {
    this.loadOrder();
  }

  private loadOrder(): void {
    this.orderService.getOrders().subscribe(
      res => {
        this.orders = res;
      }
    );
  }

  public onAddOrder(): void {
    this.displayDetailDialog = true;
  }

  public onSelectOrder(el: number): void {
    this.orderIdSeleted = el;
    this.displayDetailDialog = true;
  }

  public onDeleteOrder(el: number, nome: string): void {
    this.value = nome;
    this.idToDelete = el;
    this.type = "Ordine";
  }

  public closeDialog(): void {
    this.loadOrder();
    this.orderIdSeleted = null;
  }

  public setType(distributore: boolean): string {
    if (distributore) {
      return 'distributori';
    } else {
      return 'case_editrici';
    }
  }

  confirmDelete(evt) {
    if (evt == true) {
      this.orderService.updateOrderBookingsToWaitingStatus(this.idToDelete)
        .subscribe(
          res => {
            this.orderService.deleteOrder(this.idToDelete)
              .subscribe(
                res => {
                  this.app.handleToastMessages('success', 'Completato', 'Ordine rimosso');
                  this.value = null;
                  this.idToDelete = 0;
                  this.type = null;
                  this.loadOrder();
                },
                error => {
                  this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
                }
              );
          },
          error => {
            this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
          }
        )

    }

  }


}
