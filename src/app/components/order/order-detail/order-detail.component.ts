import { Component, OnInit } from '@angular/core';
import { Publisher } from 'src/app/interfaces/publisher';
import { PublisherService } from 'src/app/services/publisher.service';
import { AppComponent } from 'src/app/app.component';
import { ConfirmationService, SelectItem } from 'primeng/api';
import { WholesalerService } from 'src/app/services/wholesaler.service';
import { OrderService } from 'src/app/services/order.service';
import * as jsPDF from 'jspdf';
import { PDFOrderGenerator } from '../pdf-order-generator';
import { OrderIdObjectType } from 'src/app/interfaces/order-id-object-type.enum';
import { BookingService } from 'src/app/services/booking.service';
import { Status } from 'src/app/interfaces/status.enum';
import { Wholesaler } from 'src/app/interfaces/wholesaler';

@Component({
  selector: 'app-order-detail',
  templateUrl: './order-detail.component.html',
  styleUrls: ['./order-detail.component.css']
})
export class OrderDetailComponent implements OnInit {
  newOrder: any;
  bookingsByPublisher: any[];
  publishers: Publisher[] = [];
  wholesalers: SelectItem[] = [];
  selectedPublisher = null;
  selectedPublishers = [];
  constructor(
    private orderService: OrderService,
    private app: AppComponent,
    private wholesalerService: WholesalerService,
    private bookingService: BookingService) { }

  ngOnInit() {
    this.initOrder();
    this.loadPublishers();
    this.loadWholsalers();
  }

  private initOrder() {
    const senderInfo = {
      name: 'LA CARIOCA DI BERNA ARIANNA',
      address: 'via Francesco Innamorati, 16/a',
      city: '06034 - FOLIGNO (PG)',
      iva: 'P. IVA 02839810542'
    };
    this.newOrder = {
      ditributore: null,
      casa_editrice: null,
      bookings: [],
      sender: senderInfo,
      orderInfo: {
        data: new Date(),
        distributore: null,
        casa_editrice: null
      }
    };
  }

  private loadPublishers() {
    this.orderService.getBookingNotInWaiting().subscribe(
      res => {
        this.publishers = [];
        this.bookingsByPublisher = [];
        res.forEach(r => {
          this.handlePublishers(r.casa_editrice);
          this.handleBookings(r);
        });
      }
    );
  }

  private loadWholsalers() {
    this.wholesalerService.getWholesalers()
      .subscribe(
        res => {
          this.wholesalers = [];
          this.wholesalers.push({
            value: null,
            label: 'Nessuno'
          });
          res.forEach(w => {
            this.wholesalers.push({
              label: w.nome,
              value: w
            });
          });
        }
      );

  }


  private handlePublishers(p: any) {
    if (this.publishers.findIndex(e => e.id === p.id) === -1) {
      this.publishers.push(p);
    }
  }

  private handleBookings(b: any) {
    const booking = {
      booking_ids: [b.prenotazione_id],
      book_id: b.libro_id,
      title: b.titolo,
      isbn: b.codice_isbn,
      quantity: 1,
      publishername: b.casa_editrice.nome
    };
    const idx = this.bookingsByPublisher.map(b => b.publisher).indexOf(b.casa_editrice.id);
    if (idx > -1) {
      const book_idx = this.bookingsByPublisher[idx].bookings.map(b => b.book_id).indexOf(booking.book_id);
      if (book_idx > -1) {
        this.bookingsByPublisher[idx].bookings[book_idx].booking_ids.push(booking.booking_ids[0]);
        this.bookingsByPublisher[idx].bookings[book_idx].quantity += 1;
      } else {
        this.bookingsByPublisher[idx].bookings.push(booking);
      }
    } else {
      this.bookingsByPublisher.push({
        publisher: b.casa_editrice.id,
        bookings: [booking]
      });
    }

  }

  public onChangePublisherSelect(evt) {
    const obj = this.bookingsByPublisher.filter(b => b.publisher === evt.value.id)[0];
    this.newOrder.bookings = obj.bookings;
    this.newOrder.orderInfo.casa_editrice = evt.value.id;
    this.selectedPublisher = evt.value;
  }

  public onChangeWholsaler(evt) {
    if (evt.value != null) {
      this.loadWholesaler(evt.value.id);
      if (this.selectedPublisher) {
        this.selectedPublishers.push(this.selectedPublisher);
      }

    } else {
      this.selectedPublisher = null;
      this.newOrder.bookings = [];
      this.selectedPublishers = [];
    }
  }

  private loadWholesaler(wholesaler_id: number) {
    this.wholesalerService.getWholesalers(wholesaler_id).subscribe(
      res => {
        this.newOrder.distributore = res[0];
        this.newOrder.orderInfo.distributore = res[0].id;
      }
    );
  }

  public save() {
    if (this.newOrder.distributore == null) {
      this.newOrder.distributore = this.selectedPublisher;
    }
    this.orderService.insertOrUpdateOrders(this.newOrder.orderInfo)
      .subscribe(
        res => {
          this.orderService.insertOrUpdateBookingOrder(
            this.generateOrderBookingsObject(res[0].id, this.newOrder.bookings))
            .subscribe(
              res1 => {
                this.newOrder.protocol = res[0].id;
                let pdf = new jsPDF('p', 'pt', 'a4');
                let generator: PDFOrderGenerator = new PDFOrderGenerator(pdf);
                generator.generatePDFOrder(this.newOrder);
                this.updateBookings();
                this.app.handleToastMessages('success', 'Completato', 'Ordine creato');
              },
              error => this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita')
            );
        },
        error => this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita')
      );
  }

  private updateBookings() {
    let student_booking = this.generateBookingsToUpdate(this.newOrder.bookings);
    student_booking.forEach(el => {
      this.bookingService.updateBookingField(el.id, { stato: el.stato })
        .subscribe(
          res => {
            this.app.handleToastMessages('success', 'Completato', 'Stato prenotazioni aggiornato');
            this.initOrder();
            this.loadPublishers();
            this.loadWholsalers();
          },
          error => this.app.handleToastMessages('error', 'Attenzione!', 'Stato prenotazioni non aggiornato')
        );
    });

  }

  private generateOrderBookingsObject(idOrder, bookings): any {
    let ret = [];

    bookings.forEach(el => {
      el.booking_ids.forEach(b =>
        ret.push({
          id_ordine: idOrder,
          id_prenotazione: b
        })
      );
    });

    return ret;
  }

  private generateBookingsToUpdate(bookings) {
    let ret = [];
    bookings.forEach(el => {
      el.booking_ids.forEach(b =>
        ret.push({
          stato: Status.IN_ORDINE,
          id: b
        })
      );
    });

    return ret;
  }

  public onChangePublisherMultiSelect(evt) {
    this.newOrder.bookings = [];
    evt.value.forEach(v => {
      const idx = this.bookingsByPublisher.map(b => b.publisher).indexOf(v.id);
      if (idx > -1) {
        this.newOrder.bookings.push(...this.bookingsByPublisher[idx].bookings);
      }
    });
    this.newOrder.orderInfo.casa_editrice = null;
    this.selectedPublishers = evt.value;
  }

}
