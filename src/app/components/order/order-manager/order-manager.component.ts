import { Component, OnInit } from '@angular/core';
import { AppComponent } from 'src/app/app.component';
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

  // public onDeleteOrder(el: number): void {
  //   this.orderService.deleteOrder(el)
  //   .subscribe(
  //     res => {
  //       this.app.handleToastMessages( 'success', 'Completato', 'Libro rimosso');
  //       this.loadOrder();
  //     },
  //     error => {
  //       this.app.handleToastMessages( 'error', 'Messaggio di errore', 'Operazione fallita');
  //     }
  //   );
  //  }

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


}
