import { Component, OnInit } from '@angular/core';
import { AppComponent } from 'src/app/app.component';
import { BookingService } from 'src/app/services/booking.service';
import { Utils } from 'src/app/util/utils';
import { Status } from 'src/app/interfaces/status.enum';
import { SelectItem } from 'primeng/api';

@Component({
  selector: 'app-booking',
  templateUrl: './booking.component.html',
  styleUrls: ['./booking.component.css']
})
export class BookingComponent implements OnInit {
  public bookings: any[];
  public totalBookings: any[];
  public displayDetailDialog: boolean;
  public bookingSeleted: any = null;
  public displayStudentDetail: boolean;
  public utils: Utils = new Utils();
  public studentId: number;
  public displayBookList: boolean;
  public classId: number;
  private bookingsWithDetail: any[];
  public status: SelectItem[] = [
    { value: 'all', label: 'Tutti' },
    { value: true, label: 'Completi' },
    { value: false, label: 'Non Completi' }
  ];
  constructor(private bookingService: BookingService, private app: AppComponent) { }

  ngOnInit() {
    this.loadBookingList();
    this.loadBookingsWithStatusDetail();
  }

  private loadBookingList(): void {
    this.bookingService.getBookingList()
      .subscribe(
        res => {
          this.bookings = res;
          this.totalBookings = res;
        }
      );
  }

  private loadBookingsWithStatusDetail() {
    this.bookingService.getBookingsWithDetail()
      .subscribe(
        res => this.bookingsWithDetail = res
      );
  }

  closeDialog(): void {
    this.loadBookingList();
    this.loadBookingsWithStatusDetail();
    this.bookingSeleted = null;
  }

  onSelectBooking(booking: any): void {
    this.bookingSeleted = { bookingId: booking.id, studentId: booking.studente };
    this.displayDetailDialog = true;
  }

  onDeleteBooking(id: number): void {
    this.bookingService.deleteBooking(id).subscribe(
      res => {
        this.app.handleToastMessages('success', 'Completato', 'Scuola rimossa');
        this.loadBookingList();
      },
      error => {
        this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
      }
    );
  }

  onAddBooking(): void {
    this.bookingSeleted = null;
    this.studentId = null;
    this.classId = null;
    this.displayDetailDialog = true;
  }

  public closeStudentDetails(event): void {
    this.displayStudentDetail = false;
    this.studentId = event.student;
    this.classId = event.class;
  }

  public notifyOpenDialog(event): void {
    switch (event) {
      case 'student':
        this.displayStudentDetail = true;
        break;
      case 'bookList':
        this.displayBookList = true;
        break;
    }
  }

  public setCircleColor(index: number) {
    let color = 'green';
    const temp = this.bookingsWithDetail.filter(b => {
      if (b.id === index) {
        return b;
      }
    })[0];
    for (let i = 0; i < temp.prenotazioni_studente.length; i++) {
      if (temp.prenotazioni_studente[i].stato === Status.ARRIVATO) {
        color = 'yellow';
        break;
      } else if (temp.prenotazioni_studente[i].stato !== Status.CONSEGNATO) {
        color = 'red';
      }
    }
    return color;
  }

  public areAllBooksArrived(index: number) {
    let check = true;
    if (!this.bookingsWithDetail && !this.bookings) {
      return false;
    }
    const temp = this.bookingsWithDetail.filter(b => {
      if (b.id === index) {
        return b;
      }
    })[0];
    for (let i = 0; i < temp.prenotazioni_studente.length; i++) {
      if (temp.prenotazioni_studente[i].stato === Status.IN_ORDINE || temp.prenotazioni_studente[i].stato === Status.ATTESA) {
        check = false;
        break;
      }
    }
    if (check === true) {
      let idx = this.bookings.map(b => b.id).indexOf(index);
      if (idx > -1) {
        this.bookings[idx].completo = true;
      }

    }
    return check;
  }

  public filterBookingsBySurname(s: string) {
    this.bookings = this.totalBookings.filter((b) => {
      return b.cognome.toLowerCase().indexOf(s) > -1;
    });
  }

  public filterBookingsBySchool(s: string) {
    this.bookings = this.totalBookings.filter((b) => {
      return b.scuola.toLowerCase().indexOf(s) > -1;
    });
  }

  public filterBystatus(evt) {
    if (evt.value === 'all') {
      this.bookings = this.totalBookings;
    } else if (evt.value === true) {
      this.bookings = this.totalBookings.filter(t => {
        if (t.completo) {
          return t;
        }
      });
    } else if (evt.value === false) {
      this.bookings = this.totalBookings.filter(t => {
        if (!t.completo) {
          return t;
        }
      });
    }
  }

}
