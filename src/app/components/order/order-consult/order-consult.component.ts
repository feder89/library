import { Component, OnInit, Input, OnChanges, SimpleChanges } from '@angular/core';
import { OrderService } from 'src/app/services/order.service';
import { Utils } from 'src/app/util/utils';
import { AppComponent } from 'src/app/app.component';
import { OrderManagerComponent } from '../order-manager/order-manager.component';

@Component({
  selector: 'app-order-consult',
  templateUrl: './order-consult.component.html',
  styleUrls: ['./order-consult.component.css']
})
export class OrderConsultComponent implements OnChanges {
  @Input() orderId;
  public protocolloExt = '';
  private utils: Utils = new Utils();
  public order: any[] = [];
  constructor(
    private orderService: OrderService,
    private app: AppComponent,
    private orderManager: OrderManagerComponent
  ) { }
  ngOnChanges(changes: SimpleChanges): void {
    if (changes['orderId'] && changes['orderId'].currentValue != null) {
      this.loadOrderDetail(changes['orderId'].currentValue);
    }
  }

  private loadOrderDetail(id) {
    this.orderService.getBookForOrder(id)
      .subscribe(
        res => {
          this.order = res;
          this.protocolloExt = res[0].protocollo_ext ? res[0].protocollo_ext : '';
        }
      );
  }

  public formatDate(dt) {
    return this.utils.formatDatetime(dt);
  }

  public getYear() {
    return new Date(this.order[0].data).getFullYear();
  }

  save() {
    this.orderService.updateProtocolOrder(this.orderId, { protocollo_ext: this.protocolloExt })
      .subscribe(
        res => {
          this.orderManager.displayDetailDialog = false;
          this.app.handleToastMessages('success', 'Completato', 'Ordine aggiornato');
        },
        error => this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita')
      );
  }

}
