import { Component, OnInit } from '@angular/core';
import { OrderService } from 'src/app/services/order.service';
import { AppComponent } from 'src/app/app.component';
import { SelectItem } from 'primeng/api';
import { BookingService } from 'src/app/services/booking.service';
import { Status } from 'src/app/interfaces/status.enum';
@Component({
  selector: 'app-received-order-registry',
  templateUrl: './received-order-registry.component.html',
  styleUrls: ['./received-order-registry.component.css']
})
export class ReceivedOrderRegistryComponent implements OnInit {
  public waitingBooks: any[];
  public allWaitingBooks: any[];
  public toBeUpdated: any[];
  private waitingBookings: any[];
  private numbers: SelectItem[];

  constructor(
    private orderService: OrderService,
    private app: AppComponent,
    private bookingService: BookingService
  ) { }

  ngOnInit() {
    this.populateSelectItem();
    this.loadWaitingBooks();
    this.loadWaitingBookings();
  }

  private loadWaitingBookings() {
    this.orderService.getWaitingBookings()
      .subscribe(
        res => this.waitingBookings = res
      );
  }

  private loadWaitingBooks() {
    this.orderService.getWaitingBooks()
      .subscribe(
        res => {
          res.forEach(r => {
            r.arrived = 0;
          });
          this.waitingBooks = res;
          this.allWaitingBooks = res;
        }
      );
  }

  private populateSelectItem() {
    this.numbers = [];
    for (let i = 0; i <= 100; i++) {
      this.numbers.push({
        label: i.toString(),
        value: i
      });
    }
  }

  public getDropboxValues(num): SelectItem[] {
    return this.numbers.slice(0, num + 1);
  }


  public save() {
    let filteredBookings: any[] = [];
    this.toBeUpdated.forEach(tbu => {
      let temp = this.waitingBookings.filter(wb => {
        if (wb.prenotazioni_studente.libro === tbu.libro.id) {
          return wb;
        }
      });
      filteredBookings.push({ booking: temp, num: tbu.arrived });
    });
    filteredBookings.forEach(fb => {
      fb.booking.sort(this.compare);
    });

    this.updateBookings(filteredBookings);

  }

  private compare(a, b) {
    if (a.prenotazione.data < b.prenotazione.data) {
      return -1;
    }
    if (a.prenotazione.data > b.prenotazione.data) {
      return 1;
    }
    return 0;
  }

  private updateBookings(bkgs: any[]) {
    bkgs.forEach(b => {
      for (let i = 0; i < b.num; i++) {
        this.bookingService.updateBookingField(b.booking[i].prenotazioni_studente.id, { stato: Status.ARRIVATO })
          .subscribe(
            res => this.app.handleToastMessages('success', 'Completato', 'Stato prenotazioni aggiornato'),
            error => this.app.handleToastMessages('error', 'Attenzione!', 'Stato prenotazioni non aggiornato')
          );
      }
    });
  }

  public filterBooks(s: string) {
    this.waitingBooks = this.allWaitingBooks.filter((b) => {
      return b.libro.codice_isbn.toLowerCase().indexOf(s) > -1;
    })
  }
}
