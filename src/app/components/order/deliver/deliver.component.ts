import { Component, OnInit, ChangeDetectionStrategy } from '@angular/core';
import { OrderService } from 'src/app/services/order.service';
import { AppComponent } from 'src/app/app.component';
import { BookingService } from 'src/app/services/booking.service';
import { load } from '@angular/core/src/render3/instructions';
import { Status } from 'src/app/interfaces/status.enum';
import { SelectItem } from 'primeng/api';

@Component({
  selector: 'app-deliver',
  templateUrl: './deliver.component.html',
  styleUrls: ['./deliver.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DeliverComponent implements OnInit {
  public students: SelectItem[] = [];
  private allArrivedBooks;
  public deliveringBooks = [];
  public toBeDelivered = [];
  public idStudent;
  public displayDetailDialog: Boolean;

  constructor(private orderService: OrderService,
    private app: AppComponent,
    private bookingService: BookingService) { }

  ngOnInit() {
    this.loadArrivedBooksByStudent();
  }

  private loadArrivedBooksByStudent() {
    this.orderService.getArrivedOrdersByStudent()
      .subscribe(
        res => {
          this.students = [];
          this.allArrivedBooks = [];
          res.forEach(r => {
            this.students.push({
              value: r.studente.id,
              label: r.studente.nome + ' ' + r.studente.cognome
            });
            this.allArrivedBooks.push(...r.libri);
          });
        }
      );
  }

  public onChangeStudent(evt) {
    this.deliveringBooks = this.allArrivedBooks.filter(b => {
      return b.studente === evt.value;
    });
    this.idStudent = evt.value;
  }

  public saveDelivered() {
    let bool: Boolean = false;
    this.toBeDelivered.forEach(d => {
      this.bookingService.updateBookingField(d.prenotazione, { stato: Status.CONSEGNATO })
        .subscribe(
          res => {
            this.app.handleToastMessages('success', 'Completato', 'Ordine Aggiornato');
            bool = true;
          },
          error => {
            this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
            bool = false;
          }
        );
    });
    if (bool) {
      this.loadArrivedBooksByStudent();
    }
  }

  public openBooklist() {
    this.displayDetailDialog = true;
  }

}
