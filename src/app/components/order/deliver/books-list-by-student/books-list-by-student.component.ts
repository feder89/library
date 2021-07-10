import { Component, OnInit, OnChanges, SimpleChanges, Input } from '@angular/core';
import { AppComponent } from 'src/app/app.component';
import { BookingService } from 'src/app/services/booking.service';
import * as jsPDF from 'jspdf';
import { PDFOrderGenerator } from '../../pdf-order-generator';
import { Utils } from 'src/app/util/utils';
import { SelectItem } from 'primeng/api';
const senderInfo = {
  name: 'LA CARIOCA DI BERNA ARIANNA',
  address: 'via Francesco Innamorati, 16/a',
  city: '06034 - FOLIGNO (PG)',
  iva: 'P. IVA 02839810542',
  email: 'bernaarianna79@gmail.com'
};
@Component({
  selector: 'app-books-list-by-student',
  templateUrl: './books-list-by-student.component.html',
  styleUrls: ['./books-list-by-student.component.css']
})
export class BooksListByStudentComponent implements OnChanges {
  @Input() studentId: number;
  public bookings: SelectItem[] = [];
  private utils = new Utils();

  public bookList: any = {
    bookings: [],
    student: {}
  };
  constructor(private app: AppComponent,
    private bookingService: BookingService) { }
  ngOnChanges(changes: SimpleChanges): void {
    if (changes['studentId'] && changes['studentId'].currentValue != null) {
      this.loadBookingsByStudent(changes['studentId'].currentValue);
    }
  }

  private loadBookingsByStudent(idStudent) {
    this.bookingService.getBookingListByStudent(idStudent)
      .subscribe(
        res => {
          this.bookings = [];
          res.forEach(r => {
            this.bookings.push({
              value: r.id,
              label: r.nome + ' ' + r.cognome
            });
          });

        }
      );
  }

  public onChangeBookings(evt) {
    this.bookingService.getBookingsDetailByBookingId(evt.value)
      .subscribe(
        res => {
          this.bookList = this.generateObjToPDF(res[0]);
        }
      )
  }

  private generateObjToPDF(obj) {
    let ret: any = {
      bookings: [],
      student: {},
      sender: senderInfo
    };
    ret.student = {
      nome: obj.prenotazioni_studente[0].studenti.nome,
      cognome: obj.prenotazioni_studente[0].studenti.cognome,
      scuola: obj.prenotazioni_studente[0].studenti.classi.scuole.nome,
      tipo: obj.prenotazioni_studente[0].studenti.classi.scuole.tipologia,
      classe: obj.prenotazioni_studente[0].studenti.classi.nome,
      data: this.utils.formatDatetime(obj.data)
    };
    let bookings = [];
    obj.prenotazioni_studente.forEach(p => {
      bookings.push({
        titolo: p.libri.titolo,
        isbn: p.libri.codice_isbn,
        casa_editrice: p.libri.case_editrici.nome,
        materia: p.libri.materia,
        prezzo: p.libri.prezzo.toFixed(2),
        firma: '',
        tomi: '',
        cd: '',
        cedola: p.cedola ? 'SI' : 'NO'
      });
    });
    ret.bookings = bookings;
    return ret;
  }

  public printPDF() {
    let pdf = new jsPDF('l', 'pt', 'a4');
    let generator: PDFOrderGenerator = new PDFOrderGenerator(pdf);
    generator.generateBookListPDF(this.bookList);
  }

}
