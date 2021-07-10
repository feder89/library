import { Component, OnInit } from '@angular/core';
import { OrderService } from 'src/app/services/order.service';
import { AppComponent } from 'src/app/app.component';
import * as _ from 'lodash';
import { Utils } from 'src/app/util/utils';
import * as jsPDF from 'jspdf';
import { PDFOrderGenerator } from '../order/pdf-order-generator';



@Component({
  selector: 'app-reminder',
  templateUrl: './reminder.component.html',
  styleUrls: ['./reminder.component.css']
})
export class ReminderComponent implements OnInit {
  public util: Utils = new Utils();
  toBeReminded: any[];
  orders;
  wholesaler: any = null;
  constructor(
    private orderService: OrderService,
    app: AppComponent
  ) { }

  ngOnInit() {
    this.loadAll();
  }

  private loadAll() {
    this.orderService.getWholsalersAndPublisherToBeReminded()
      .subscribe(
        res => this.toBeReminded = res
      );
  }

  onSelect(evt) {
    this.orderService.getOrdersToBeReminded(evt.value.id, evt.value.tipo)
      .subscribe(
        res => {
          const temp = _.groupBy(res, (e) => { return e.id_ordine; });
          this.orders = [];
          for (let key in temp) {
            const value = temp[key];
            const _books = _.groupBy(value, (e) => { return e.libro.libro.id; });
            const books = [];
            for (let key_ in _books) {
              const _v = _books[key_];
              books.push({
                quantity: _v.length,
                titolo: _v[0].libro.libro.titolo,
                codice_isbn: _v[0].libro.libro.codice_isbn,
                ce_nome: (_v[0].libro.ce_nome) ? _v[0].libro.ce_nome : ''
              });
            }
            this.orders.push({ id_ordine: key, books: books, data: value[0].data });
          }
          this.wholesaler = res[0].distributore;
        }
      );


  }

  public printRemind() {
    const senderInfo = {
      name: 'LA CARIOCA DI BERNA ARIANNA',
      address: 'via Francesco Innamorati, 16/a',
      city: '06034 - FOLIGNO (PG)',
      iva: 'P. IVA 02839810542'
    };
    let pdf = new jsPDF('p', 'pt', 'a4');
    let generator: PDFOrderGenerator = new PDFOrderGenerator(pdf);
    generator.generatePDFRemind(senderInfo, this.orders, this.wholesaler);
  }

}
